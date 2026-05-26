#[path = "../src/generated_cases.rs"]
mod generated_cases;

use criterion::{black_box, criterion_group, criterion_main, Criterion};
use generated_cases::{CASES, DATASET_VERSION};
use nalgebra::{DMatrix, DVector};
use std::time::Duration;

struct Shape {
    rows: usize,
    cols: usize,
    rhs_cols: usize,
}

struct Inputs {
    data_a: &'static [f64],
    data_b: &'static [f64],
}

struct CaseFile {
    case_id: &'static str,
    operation: &'static str,
    family: &'static str,
    shape: Shape,
    inputs: Inputs,
}

struct ApiPipeline {
    case_file: &'static CaseFile,
    matrix_a: DMatrix<f64>,
    rhs_matrix: DMatrix<f64>,
    rhs_vector: DVector<f64>,
    work_vector_a: DVector<f64>,
    work_vector_b: DVector<f64>,
    aux_vector: Vec<f64>,
}

fn matrix(rows: usize, cols: usize, data: &[f64]) -> DMatrix<f64> {
    DMatrix::from_row_slice(rows, cols, data)
}

fn vector(data: &[f64]) -> DVector<f64> {
    DVector::from_row_slice(data)
}

fn mix(acc: u64, bits: u64) -> u64 {
    (acc ^ bits).wrapping_mul(1099511628211)
}

fn checksum_values<I: IntoIterator<Item = f64>>(values: I, seed: u64) -> u64 {
    values
        .into_iter()
        .fold(seed, |acc, value| mix(acc, value.to_bits()))
}

fn checksum_matrix(matrix: &DMatrix<f64>) -> u64 {
    let seed = mix(1469598103934665603, matrix.nrows() as u64);
    let seed = mix(seed, matrix.ncols() as u64);
    checksum_values(matrix.iter().copied(), seed)
}

fn checksum_vector(vector: &DVector<f64>) -> u64 {
    checksum_values(vector.iter().copied(), 1469598103934665603)
}

fn checksum_scalar(value: f64) -> u64 {
    mix(1469598103934665603, value.to_bits())
}

fn checksum_int(value: usize) -> u64 {
    mix(1469598103934665603, value as u64)
}

impl ApiPipeline {
    fn new(case_file: &'static CaseFile) -> Self {
        let rows = case_file.shape.rows;
        let cols = case_file.shape.cols;
        let rhs_cols = case_file.shape.rhs_cols;
        let square = rows.max(cols).max(rhs_cols);
        Self {
            case_file,
            matrix_a: matrix(rows, cols, case_file.inputs.data_a),
            rhs_matrix: if case_file.operation == "mul" {
                matrix(cols, rhs_cols, case_file.inputs.data_b)
            } else {
                DMatrix::zeros(0, 0)
            },
            rhs_vector: if case_file.operation == "mul_vec" {
                vector(case_file.inputs.data_b)
            } else {
                DVector::zeros(0)
            },
            work_vector_a: DVector::zeros(square),
            work_vector_b: DVector::zeros(square),
            aux_vector: vec![0.0; square],
        }
    }

    fn run(&mut self) -> u64 {
        match self.case_file.operation {
            "mul" => checksum_matrix(&(&self.matrix_a * &self.rhs_matrix)),
            "mul_vec" => checksum_vector(&(&self.matrix_a * &self.rhs_vector)),
            "determinant" => checksum_scalar(self.matrix_a.clone().determinant()),
            "inverse" => match self.matrix_a.clone().try_inverse() {
                Some(value) => checksum_matrix(&value),
                None => mix(1469598103934665603, 0xDEAD0001),
            },
            "rank" => checksum_int(self.matrix_a.clone().rank(1.0e-8)),
            "reduce_row_elimination" => checksum_matrix(&self.rref()),
            "cholesky_decomposition" => match self.matrix_a.clone().cholesky() {
                Some(value) => checksum_matrix(&value.unpack()),
                None => mix(1469598103934665603, 0xDEAD0002),
            },
            "eigen" => {
                let eigen = self.matrix_a.clone().symmetric_eigen();
                let checksum = checksum_vector(&eigen.eigenvalues);
                checksum_values(eigen.eigenvectors.iter().copied(), checksum)
            }
            "power_method" => match self.power_method(80) {
                Some((value, vector)) => checksum_values(vector.iter().copied(), checksum_scalar(value)),
                None => mix(1469598103934665603, 0xDEAD0003),
            },
            _ => unreachable!("unsupported operation: {}", self.case_file.operation),
        }
    }

    // nalgebra does not expose a one-call RREF API, so this remains a local fallback.
    fn rref(&self) -> DMatrix<f64> {
        let mut out = self.matrix_a.clone();
        let rows = out.nrows();
        let cols = out.ncols();
        let mut pivot_col = 0;
        for pivot_row in 0..rows {
            while pivot_col < cols {
                let mut max_row = pivot_row;
                for candidate in (pivot_row + 1)..rows {
                    if out[(candidate, pivot_col)].abs() > out[(max_row, pivot_col)].abs() {
                        max_row = candidate;
                    }
                }
                if max_row != pivot_row {
                    out.swap_rows(pivot_row, max_row);
                }
                if out[(pivot_row, pivot_col)] == 0.0 {
                    pivot_col += 1;
                    continue;
                }
                let pivot = out[(pivot_row, pivot_col)];
                for col in 0..cols {
                    out[(pivot_row, col)] /= pivot;
                }
                for row in 0..rows {
                    if row == pivot_row {
                        continue;
                    }
                    let factor = out[(row, pivot_col)];
                    for col in 0..cols {
                        out[(row, col)] -= factor * out[(pivot_row, col)];
                    }
                }
                pivot_col += 1;
                break;
            }
        }
        out
    }

    // nalgebra does not expose a direct public power-method helper for these cases.
    fn power_method(&mut self, max_iterations: usize) -> Option<(f64, DVector<f64>)> {
        let n = self.matrix_a.nrows();
        if n == 0 || n != self.matrix_a.ncols() {
            return None;
        }
        let tol = 1.0e-9;
        for i in 0..n {
            self.work_vector_a[i] = 1.0;
        }
        for _ in 0..max_iterations {
            let next = &self.matrix_a * &self.work_vector_a.rows(0, n);
            for i in 0..n {
                self.work_vector_b[i] = next[i];
            }
            let mut scale = 0.0_f64;
            for i in 0..n {
                scale = scale.max(self.work_vector_b[i].abs());
            }
            if scale <= tol {
                return None;
            }
            for i in 0..n {
                self.work_vector_a[i] = self.work_vector_b[i] / scale;
            }
            let current = &self.matrix_a * &self.work_vector_a.rows(0, n);
            for i in 0..n {
                self.aux_vector[i] = current[i];
            }
            let mut numerator = 0.0;
            let mut denominator = 0.0;
            for i in 0..n {
                numerator += self.work_vector_a[i] * self.aux_vector[i];
                denominator += self.work_vector_a[i] * self.work_vector_a[i];
            }
            if denominator.abs() <= tol {
                return None;
            }
            let lambda = numerator / denominator;
            let mut residual = 0.0_f64;
            for i in 0..n {
                residual = residual.max((self.aux_vector[i] - self.work_vector_a[i] * lambda).abs());
            }
            if residual <= tol {
                let mut vector = DVector::zeros(n);
                for i in 0..n {
                    vector[i] = self.work_vector_a[i];
                }
                return Some((lambda, vector));
            }
        }
        None
    }
}

fn kernel_benchmarks(c: &mut Criterion) {
    assert_eq!(DATASET_VERSION, "v2");
    for case_file in CASES {
        let mut pipeline = ApiPipeline::new(case_file);
        let mut group = c.benchmark_group(case_file.operation);
        group.bench_function(case_file.case_id, |b| b.iter(|| black_box(pipeline.run())));
        group.finish();
    }
}

fn criterion_config() -> Criterion {
    Criterion::default()
        .sample_size(15)
        .warm_up_time(Duration::from_millis(250))
        .measurement_time(Duration::from_secs(1))
}

criterion_group! {
    name = benches;
    config = criterion_config();
    targets = kernel_benchmarks
}
criterion_main!(benches);

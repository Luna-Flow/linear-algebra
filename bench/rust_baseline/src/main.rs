mod generated_cases;

use generated_cases::find_case;
use nalgebra::{Cholesky, DMatrix, DVector, SymmetricEigen};
use std::time::Instant;

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

struct WarmStats {
    median_ns: u64,
    p90_ns: u64,
    mad_ns: u64,
    checksum: u64,
}

enum PreparedRhs {
    None,
    Matrix(DMatrix<f64>),
    Vector(DVector<f64>),
}

struct PreparedCase {
    case_file: &'static CaseFile,
    matrix_a: DMatrix<f64>,
    rhs: PreparedRhs,
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

fn power_method(matrix: &DMatrix<f64>, max_iterations: usize) -> Option<(f64, DVector<f64>)> {
    if matrix.nrows() == 0 || matrix.nrows() != matrix.ncols() {
        return None;
    }
    let tol = 1.0e-9;
    let mut x = DVector::from_element(matrix.nrows(), 1.0);
    for _ in 0..max_iterations {
        let y = matrix * &x;
        let scale = y.iter().map(|value| value.abs()).fold(0.0_f64, f64::max);
        if scale <= tol {
            return None;
        }
        x = y.map(|value| value / scale);
        let ax = matrix * &x;
        let numerator = x.dot(&ax);
        let denominator = x.dot(&x);
        if denominator.abs() <= tol {
            return None;
        }
        let lambda = numerator / denominator;
        let residual = ax
            .iter()
            .zip(x.iter())
            .map(|(lhs, rhs)| (lhs - rhs * lambda).abs())
            .fold(0.0_f64, f64::max);
        if residual <= tol {
            return Some((lambda, x));
        }
    }
    None
}

fn reduced_row_echelon(mut matrix: DMatrix<f64>) -> DMatrix<f64> {
    let rows = matrix.nrows();
    let cols = matrix.ncols();
    let tol = 1.0e-9;
    let mut pivot_col = 0;
    for pivot_row in 0..rows {
        while pivot_col < cols {
            let mut max_row = pivot_row;
            let mut max_abs = matrix[(pivot_row, pivot_col)].abs();
            for candidate in (pivot_row + 1)..rows {
                let candidate_abs = matrix[(candidate, pivot_col)].abs();
                if candidate_abs > max_abs {
                    max_abs = candidate_abs;
                    max_row = candidate;
                }
            }
            if max_abs < tol {
                pivot_col += 1;
                continue;
            }
            if max_row != pivot_row {
                matrix.swap_rows(pivot_row, max_row);
            }
            let pivot = matrix[(pivot_row, pivot_col)];
            for col in 0..cols {
                matrix[(pivot_row, col)] /= pivot;
            }
            for row in 0..rows {
                if row == pivot_row {
                    continue;
                }
                let factor = matrix[(row, pivot_col)];
                if factor.abs() < tol {
                    continue;
                }
                for col in 0..cols {
                    matrix[(row, col)] -= factor * matrix[(pivot_row, col)];
                }
            }
            pivot_col += 1;
            break;
        }
    }
    matrix
}

fn rank(matrix: &DMatrix<f64>) -> usize {
    let reduced = reduced_row_echelon(matrix.clone());
    let tol = 1.0e-8;
    reduced
        .row_iter()
        .filter(|row| row.iter().any(|value| value.abs() > tol))
        .count()
}

fn prepare_case(case_file: &'static CaseFile) -> PreparedCase {
    let matrix_a = matrix(case_file.shape.rows, case_file.shape.cols, case_file.inputs.data_a);
    let rhs = match case_file.operation {
        "mul" => PreparedRhs::Matrix(matrix(
            case_file.shape.cols,
            case_file.shape.rhs_cols,
            case_file.inputs.data_b,
        )),
        "mul_vec" => PreparedRhs::Vector(vector(case_file.inputs.data_b)),
        _ => PreparedRhs::None,
    };
    PreparedCase {
        case_file,
        matrix_a,
        rhs,
    }
}

fn run_case(prepared: &PreparedCase) -> Option<u64> {
    let case_file = prepared.case_file;
    match case_file.operation {
        "mul" => {
            let PreparedRhs::Matrix(b) = &prepared.rhs else {
                unreachable!();
            };
            Some(checksum_matrix(&(&prepared.matrix_a * b)))
        }
        "mul_vec" => {
            let PreparedRhs::Vector(v) = &prepared.rhs else {
                unreachable!();
            };
            Some(checksum_vector(&(&prepared.matrix_a * v)))
        }
        "determinant" => Some(checksum_scalar(prepared.matrix_a.determinant())),
        "inverse" => prepared
            .matrix_a
            .clone()
            .try_inverse()
            .map(|value| checksum_matrix(&value)),
        "rank" => Some(checksum_int(rank(&prepared.matrix_a))),
        "reduce_row_elimination" => {
            Some(checksum_matrix(&reduced_row_echelon(prepared.matrix_a.clone())))
        }
        "cholesky_decomposition" => Cholesky::new(prepared.matrix_a.clone())
            .map(|value| checksum_matrix(&value.l())),
        "eigen" => {
            let eigen = SymmetricEigen::new(prepared.matrix_a.clone());
            let checksum = checksum_vector(&eigen.eigenvalues);
            Some(checksum_values(eigen.eigenvectors.iter().copied(), checksum))
        }
        "power_method" => power_method(&prepared.matrix_a, 80).map(|(value, vector)| {
            checksum_values(vector.iter().copied(), checksum_scalar(value))
        }),
        _ => None,
    }
}

fn trimmed_stats(samples: &[u64]) -> (u64, u64, u64) {
    let mut values = samples.to_vec();
    values.sort_unstable();
    let trimmed = if values.len() > 5 {
        &values[2..values.len() - 2]
    } else {
        &values[..]
    };
    let median = trimmed[trimmed.len() / 2];
    let p90_index = ((trimmed.len() as f64 * 0.9).ceil() as usize).saturating_sub(1);
    let p90 = trimmed[p90_index.min(trimmed.len() - 1)];
    let mut deviations: Vec<u64> = trimmed.iter().map(|value| value.abs_diff(median)).collect();
    deviations.sort_unstable();
    let mad = deviations[deviations.len() / 2];
    (median, p90, mad)
}

fn warm_stats(prepared: &PreparedCase) -> Option<WarmStats> {
    let warmup = match prepared.case_file.operation {
        "mul_vec" => 12,
        "rank" | "reduce_row_elimination" => 4,
        "determinant" | "inverse" | "cholesky_decomposition" | "eigen" | "power_method" => 2,
        _ => 3,
    };
    for _ in 0..warmup {
        run_case(prepared)?;
    }
    let samples = 15;
    let mut timings = Vec::with_capacity(samples);
    let mut checksum = 0_u64;
    for _ in 0..samples {
        let started = Instant::now();
        checksum = run_case(prepared)?;
        timings.push(started.elapsed().as_nanos() as u64);
    }
    let (median_ns, p90_ns, mad_ns) = trimmed_stats(&timings);
    Some(WarmStats {
        median_ns,
        p90_ns,
        mad_ns,
        checksum,
    })
}

fn print_cold(prepared: &PreparedCase) {
    match run_case(prepared) {
        Some(checksum) => {
            println!(
                "{{\"case_id\":\"{}\",\"operation\":\"{}\",\"family\":\"{}\",\"checksum\":\"{}\"}}",
                prepared.case_file.case_id,
                prepared.case_file.operation,
                prepared.case_file.family,
                checksum
            );
        }
        None => {
            eprintln!("unsupported operation: {}", prepared.case_file.operation);
            std::process::exit(2);
        }
    }
}

fn print_warm(prepared: &PreparedCase) {
    match warm_stats(prepared) {
        Some(stats) => {
            println!(
                "{{\"case_id\":\"{}\",\"operation\":\"{}\",\"family\":\"{}\",\"checksum\":\"{}\",\"median_ns\":{},\"p90_ns\":{},\"mad_ns\":{}}}",
                prepared.case_file.case_id,
                prepared.case_file.operation,
                prepared.case_file.family,
                stats.checksum,
                stats.median_ns,
                stats.p90_ns,
                stats.mad_ns
            );
        }
        None => {
            eprintln!("unsupported operation: {}", prepared.case_file.operation);
            std::process::exit(2);
        }
    }
}

fn main() {
    let mut args = std::env::args().skip(1);
    let first = args.next().expect("expected case id or --warm");
    let (warm_mode, case_id) = if first == "--warm" {
        (true, args.next().expect("expected case id after --warm"))
    } else {
        (false, first)
    };
    let case_file = find_case(&case_id).expect("unknown benchmark case");
    let prepared = prepare_case(case_file);
    if warm_mode {
        print_warm(&prepared);
    } else {
        print_cold(&prepared);
    }
}

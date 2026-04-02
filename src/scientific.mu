# ─────────────────────────────────────────────────────────────────────────────
# scientific.mu  —  Musil scientific library  (v0.5)
#
# Requires: stdlib.mu loaded, and the scientific C++ builtins registered
#           via add_scientific(env) in your application.
#
# Matrix representation:
#   A matrix is an Array of Vectors (Array of NumVal).
#   M[i]    -> row i as a numeric vector
#   M[i][j] -> scalar element at row i, column j
#
# Builtin primitives provided by scientific.h:
#   matdisp, matadd, matsub, matmul, hadamard, transpose
#   nrows, ncols, matsum, getrows, getcols
#   eye, rand, zeros, ones, bpf
#   inv, det, diag, rank, solve
#   matcol, stack2, hstack, vstack
#   median, linefit, norm, dist, matmean, matstd, cov, corr, zscore
#   pca, kmeans, knn
# ─────────────────────────────────────────────────────────────────────────────

# ── Basic vector / matrix helpers ─────────────────────────────────────────────

# Single row of matrix M (as a 1 x n matrix, i.e. Array containing one vector)
proc row (M, idx) {
    return getrows(M, idx, idx)
}

# Single column of matrix M (as an m x 1 matrix)
proc col (M, idx) {
    return getcols(M, idx, idx)
}

# Random vector of length n  (values in [-1, 1])
proc randvec (n) { return rand(n) }

# Random matrix with given rows and cols
proc randmat (rows, cols) { return rand(cols, rows) }

# Operator aliases for cleaner code
proc mat_add (A, B) { return matadd(A, B) }
proc mat_sub (A, B) { return matsub(A, B) }
proc mat_mul (A, B) { return matmul(A, B) }

# Zero / one vectors and matrices
proc zerosvec (n)         { return zeros(n) }
proc zerosmat (rows, cols) { return zeros(cols, rows) }
proc onesvec  (n)         { return ones(n) }
proc onesmat  (rows, cols) { return ones(cols, rows) }

# Build a matrix from an Array of Arrays (convert each row to a vector).
# Input: [[r0c0, r0c1, ...], [r1c0, ...], ...]
# Output: Array of NumVal rows (the standard matrix format)
proc list2mat (rows_arr) {
    var out = []
    for (var row_data in rows_arr) {
        push(out, to_vec(row_data))     # convert each inner array to a vector
    }
    return out
}

# ── Linear regression (normal equations + 1D fallback) ───────────────────────
#
# X: n x d matrix (Array of Vectors; rows = samples, cols = features)
# Y: n x 1 matrix (Array containing one-element vectors)
#
# For d = 1: uses the C++ linefit primitive (returns vec(slope, intercept))
# For d > 1: normal equations: beta = (X^T X)^(-1) X^T Y

proc linreg_fit (X, Y) {
    var d = ncols(X)
    if (d == 1) {
        # 1D case: extract column vectors, use linefit
        var x_vec = matcol(X, 0)
        var y_vec = matcol(Y, 0)
        # linefit returns vec(slope, intercept) — wrap as 1 x 2 matrix
        var lf = linefit(x_vec, y_vec)
        # return just the slope as a 1 x 1 matrix [[slope]]
        return getcols([lf], 0, 0)
    } else {
        # General: normal equations
        var Xt          = transpose(X)
        var XtX         = matmul(Xt, X)
        var XtX_inv     = inv(XtX)
        var XtX_inv_Xt  = matmul(XtX_inv, Xt)
        return matmul(XtX_inv_Xt, Y)
    }
}

# Predict: X_new (n_new x d), beta (d x 1) -> n_new x 1
proc linreg_predict (X_new, beta) {
    return matmul(X_new, beta)
}

# Residuals: Y - X * beta  (n x 1 matrix)
proc linreg_residuals (X, Y, beta) {
    return matsub(Y, linreg_predict(X, beta))
}

# ── PCA helpers ───────────────────────────────────────────────────────────────
#
# The C++ pca(M) returns a (d x d+1) matrix:
#   - first d columns: eigenvectors (sorted by descending eigenvalue)
#   - last column:     eigenvalues
#
# pca_decompose returns [P, eigvecs, eigvals]

proc pca_decompose (X) {
    var P          = pca(X)
    var last_col   = ncols(P) - 1
    var eigvecs    = getcols(P, 0, last_col - 1)  # d x d matrix
    var eigvals    = getcols(P, last_col, last_col) # d x 1 matrix
    return [P, eigvecs, eigvals]
}

proc pca_eigvecs (X) {
    return pca_decompose(X)[1]
}

proc pca_eigvals (X) {
    return pca_decompose(X)[2]
}

# Project X onto the first k principal components.
# Returns: n x k matrix of scores
proc pca_scores (X, k) {
    var dec    = pca_decompose(X)
    var eigvecs = dec[1]                    # d x d
    var V_k    = getcols(eigvecs, 0, k - 1) # d x k
    return matmul(X, V_k)                  # n x d  *  d x k  =  n x k
}

# ── K-means helpers ───────────────────────────────────────────────────────────
#
# C++ kmeans(M, K) returns [labels_vector, centroids_matrix]
#   labels_vector: NumVal of length n (cluster indices)
#   centroids_matrix: K x m Array of Vectors

proc kmeans_labels    (km_result) { return km_result[0] }
proc kmeans_centroids (km_result) { return km_result[1] }

proc kmeans_run_labels (data, K) {
    return kmeans_labels(kmeans(data, K))
}

proc kmeans_run_centroids (data, K) {
    return kmeans_centroids(kmeans(data, K))
}

# ── KNN helpers ───────────────────────────────────────────────────────────────
#
# C++ knn(train, K, queries) -> Array of label strings
# train: Array of [features_vector, label] pairs
# queries: Array of NumVals

proc knn_predict (TRAIN, K, QUERIES) {
    return knn(TRAIN, K, QUERIES)
}

# Predict for a single query point (returns one label string)
proc knn_predict_one (TRAIN, K, Q) {
    return knn(TRAIN, K, [Q])[0]
}

# Pack training set and K into a model tuple
proc knntrain (trainset, K) {
    return [trainset, K]
}

# Classify a test set using a packed model.
# Each test sample is [features_vector, label]; returns Array of predicted labels.
proc knntest (model, testset) {
    var TRAIN = model[0]
    var K     = model[1]
    var test_features = map(testset, proc (sample) { return sample[0] })
    return knn_predict(TRAIN, K, test_features)
}

# Count number of correct predictions
# preds: Array of predicted label strings
# data:  Array of [features, true_label] samples
proc correct_count (preds, data) {
    var n      = len(preds)
    var count  = 0
    var i      = 0
    while (i < n) {
        var true_label = data[i][1]
        if (preds[i] == str(true_label)) { count = count + 1 }
        i = i + 1
    }
    return count
}

# Classification accuracy in [0, 1]
proc accuracy (preds, data) {
    var n = len(preds)
    if (n == 0) { return 0 }
    return correct_count(preds, data) / n
}

# ── Preprocessing helpers ─────────────────────────────────────────────────────

# Column-wise z-score standardisation (alias for the C++ builtin)
proc standardize (X) { return zscore(X) }

# Covariance matrix after z-score normalisation
proc cov_from_zscore (X) { return cov(zscore(X)) }

# eof

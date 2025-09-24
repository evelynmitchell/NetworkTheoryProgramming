-- Network Research Database Schema
-- Designed for spectral property algorithm performance analysis

-- Core network metadata
CREATE TABLE networks (
    network_id INTEGER PRIMARY KEY,
    name TEXT NOT NULL,
    source TEXT NOT NULL, -- 'generated', 'snap', 'konect', etc.
    source_url TEXT,
    network_type TEXT, -- 'social', 'biological', 'synthetic', etc.
    is_directed BOOLEAN NOT NULL,
    is_weighted BOOLEAN NOT NULL,
    node_count INTEGER NOT NULL,
    edge_count INTEGER NOT NULL,
    description TEXT,
    generation_params JSON, -- for synthetic networks
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    file_path TEXT -- path to edge list or adjacency matrix
);

-- Algorithm implementations and versions
CREATE TABLE algorithms (
    algorithm_id INTEGER PRIMARY KEY,
    name TEXT NOT NULL, -- 'NetworkX_eigenvalues', 'SciPy_ARPACK', etc.
    category TEXT NOT NULL, -- 'spectral_gap', 'full_spectrum', 'laplacian', etc.
    implementation TEXT NOT NULL, -- 'networkx', 'scipy', 'igraph', etc.
    version TEXT, -- library version
    method_details TEXT, -- specific solver, parameters
    parameters JSON, -- algorithm-specific params
    description TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- System configuration for reproducibility
CREATE TABLE system_configs (
    config_id INTEGER PRIMARY KEY,
    python_version TEXT,
    numpy_version TEXT,
    scipy_version TEXT,
    networkx_version TEXT,
    cpu_info TEXT,
    memory_gb REAL,
    gpu_info TEXT,
    colab_runtime_type TEXT, -- 'standard', 'high-ram', 'gpu', etc.
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Main experiment runs
CREATE TABLE experiments (
    experiment_id INTEGER PRIMARY KEY,
    network_id INTEGER NOT NULL,
    algorithm_id INTEGER NOT NULL,
    system_config_id INTEGER NOT NULL,
    run_datetime TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    -- Performance metrics
    runtime_seconds REAL,
    memory_peak_mb REAL,
    cpu_percent_avg REAL,
    
    -- Algorithm-specific results
    converged BOOLEAN,
    iterations INTEGER, -- for iterative methods
    tolerance_achieved REAL,
    numerical_error REAL, -- for accuracy comparison
    
    -- Results storage
    eigenvalues JSON, -- array of computed eigenvalues
    eigenvectors_path TEXT, -- file path if too large for JSON
    spectral_gap REAL,
    spectral_radius REAL,
    algebraic_connectivity REAL,
    
    -- Error handling
    success BOOLEAN NOT NULL,
    error_message TEXT,
    
    -- Additional metrics
    condition_number REAL,
    rank_estimate INTEGER,
    
    FOREIGN KEY (network_id) REFERENCES networks (network_id),
    FOREIGN KEY (algorithm_id) REFERENCES algorithms (algorithm_id),
    FOREIGN KEY (system_config_id) REFERENCES system_configs (config_id)
);

-- Network visualizations
CREATE TABLE visualizations (
    viz_id INTEGER PRIMARY KEY,
    network_id INTEGER NOT NULL,
    layout_algorithm TEXT NOT NULL, -- 'spring', 'spectral', 'circular', etc.
    image_format TEXT DEFAULT 'PNG', -- 'PNG', 'SVG', 'PDF'
    image_blob BLOB, -- for small images
    image_path TEXT, -- for large images
    width INTEGER,
    height INTEGER,
    layout_params JSON,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    FOREIGN KEY (network_id) REFERENCES networks (network_id)
);

-- Performance comparison views for analysis
CREATE VIEW algorithm_performance AS
SELECT 
    n.name as network_name,
    n.node_count,
    n.edge_count,
    a.name as algorithm_name,
    a.category,
    AVG(e.runtime_seconds) as avg_runtime,
    STDEV(e.runtime_seconds) as runtime_std,
    AVG(e.memory_peak_mb) as avg_memory,
    COUNT(*) as run_count,
    AVG(CASE WHEN e.converged THEN 1.0 ELSE 0.0 END) as success_rate
FROM experiments e
JOIN networks n ON e.network_id = n.network_id
JOIN algorithms a ON e.algorithm_id = a.algorithm_id
WHERE e.success = 1
GROUP BY n.network_id, a.algorithm_id;

-- Indexes for query performance
CREATE INDEX idx_experiments_network ON experiments (network_id);
CREATE INDEX idx_experiments_algorithm ON experiments (algorithm_id);
CREATE INDEX idx_experiments_datetime ON experiments (run_datetime);
CREATE INDEX idx_networks_size ON networks (node_count, edge_count);
CREATE INDEX idx_algorithms_category ON algorithms (category);
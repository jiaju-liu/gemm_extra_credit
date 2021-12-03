export void gemm_ispc(uniform int m, uniform int n, uniform int k,
	 uniform double A[], uniform double B[], uniform double C[], uniform double alpha, uniform double beta) {
    uniform int blocksz = 8;
    uniform int tasks = m*n / (block_sz ** 2);

    launch[tasks] gemm_ispc_task(m, n, k, blocksz, blocks_per_row, A[],  B[], C[], alpha, beta);
     }
// don't worry abt race conds for now? or just give each task the entire thing
// slightly different kernel to support tasking
task void mandelbrot_ispc_task(uniform float x0, uniform float y0, 
                               uniform float x1, uniform float y1,
                               uniform int width, uniform int height,
                               uniform int rowsPerTask,
                               uniform int maxIterations,
                               uniform int output[])
{

    // taskIndex is an ISPC built-in
    
    uniform int ystart = taskIndex * rowsPerTask;
    uniform int yend = ystart + rowsPerTask;
    
    uniform float dx = (x1 - x0) / width;
    uniform float dy = (y1 - y0) / height;
    
    foreach (j = ystart ... yend, i = 0 ... width) {
            float x = x0 + i * dx;
            float y = y0 + j * dy;
            
            int index = j * width + i;
            output[index] = mandel(x, y, maxIterations);
    }
}

// for version 1 we have one block of b and move rows of A down then repeat
total_row_storage = blocksz * m
task void gemm_ispc_task(uniform int m, uniform int n, uniform int k, uniform int blocksz, uniform int blocks_per_row,
	 const uniform double A[], const uniform double B[], uniform double C[], uniform double alpha, uniform double beta) {
    uniform int block_y = blocks_per_row * (task_index / blocks_per_row);
    uniform int block_x = blocks_per_row * task_index - block_y;
    for (uniform int row = 0; row < m; row++) {
        // unroll this loop
        // try a foreach one way then another then benchmark perf
        
        // HOW DO I MAKE THIS MORE PARALLEL WITHOUT DEALING WITH DATA RACES
        foreach (j = 0 ... blocksz) {
            C[row*m + j + block_x] *= beta;
        }
        for (int i = 0; i < blocksz; i++) {
            foreach (j= 0 ... blocksz) {
                //output[task_index * total_row_storage + blocksz *] += A[i+block_y + row * m] * B[block_x + j + row * (block_y + i)];
                C[row * m + j + block_x] += alpha * A[i+block_y + row * m] * B[block_x + j + row * (block_y + i)];
            }
        }
    }
}

#include <stdlib.h>

int *ivector(int n) {

    return malloc(n * sizeof(int));
}

void kill_ivector(int *v) {

    free(v);
}

double **matrix(int nr, int nc) {

    double **grid;
    int j;

    grid = malloc(nr * sizeof(double *));
    for(j = 0; j < nr; j++)
        grid[j] = malloc(nc * sizeof(double));

    return grid;
}

void kill_matrix(double **grid, int nr) {

    int j;

    for(j = 0; j < nr; j++)
        free(grid[j]);
    free(grid);
}

double ***grid3(int n1, int n2, int n3) {

    double ***grid;
    int i, j;

    grid = malloc(n1 * sizeof(double **));
    for(i = 0; i < n1; i++) {
        grid[i] = malloc(n2 * sizeof(double *));
        for(j = 0; j < n2; j++)
            grid[i][j] = malloc(n3 * sizeof(double));
    }

    return grid;
}


void kill_grid3(double ***grid, int n1, int n2) {

    int i, j;

    for(i = 0; i < n1; i++) {
	for(j = 0; j < n2; j++)
	    free(grid[i][j]);
	free(grid[i]);
    }
    free(grid);
}

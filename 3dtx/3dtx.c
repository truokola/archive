#include <stdio.h>
#include <stdlib.h>
#include <math.h>
#include <gsl/gsl_multimin.h>
#include "matvec.h"
#include "fields.h"

#define DIRECT

static double sqrarg;
#define SQR(a) (sqrarg=(a), sqrarg*sqrarg)

const double pi = 3.14159265358979;

const double costh = -0.25;
const double costh1 = 1.25; /* 1-costh */
const double sinth = 0.9682;

const double gamma = -10.0;

int iter_flag = 0;

/* Data which is carried between iterations */
struct global_data {
    struct geometry geom;
    vfield n;
    vfield curl;
    sfield div;
    sfield energy_density;
};



double surface_energy_sides(struct geometry g, vfield n) {

    double sum = 0.0, prod;
    struct bnode *cell;
    double nvecx, nvecy, nvecz;
    double lvecx, lvecy;
    int k;

    cell = g.boundary;
    while(cell != NULL) {
	for(k = 0; k < n.nz; k++) {
	    nvecx = cell->w1*n.vx[cell->i][cell->j][k]
		+cell->w2*n.vx[cell->i+1][cell->j][k]
		+cell->w3*n.vx[cell->i][cell->j+1][k]
		+cell->w4*n.vx[cell->i+1][cell->j+1][k];
	    nvecy = cell->w1*n.vy[cell->i][cell->j][k]
		+cell->w2*n.vy[cell->i+1][cell->j][k]
		+cell->w3*n.vy[cell->i][cell->j+1][k]
		+cell->w4*n.vy[cell->i+1][cell->j+1][k];
	    nvecz = cell->w1*n.vz[cell->i][cell->j][k]
		+cell->w2*n.vz[cell->i+1][cell->j][k]
		+cell->w3*n.vz[cell->i][cell->j+1][k]
		+cell->w4*n.vz[cell->i+1][cell->j+1][k];

	    lvecx = nvecx*nvecz*costh1 + nvecy*sinth;
	    lvecy = nvecy*nvecz*costh1 - nvecx*sinth;
	    prod = SQR(lvecx*cell->normx + lvecy*cell->normy)*cell->seglen;
	    if (k == 0 || k == n.nz-1) sum += .5*prod;
	    else sum += prod;
	}
	cell = cell->next;
    }
	
    return sum*n.aspect*gamma/SQR(g.nr);
}


double surface_energy_topbot(struct geometry g, vfield n) {

    int i, j, k, kk = 0;
    double nvecz, lvecz;
    double sum = 0.0;

    while(kk < 2) {
	k = kk * (n.nz-1);
	for(j = 0; j < n.ny-1; j++)
	    for(i = g.firstcell[j]; i < n.nx-g.firstcell[j]-1; i++) {
		nvecz = (n.vz[i][j][k] + n.vz[i+1][j][k]
			 + n.vz[i][j+1][k]+n.vz[i+1][j+1][k])/4.0;
		lvecz = nvecz*nvecz*costh1 + costh;
		sum += lvecz*lvecz*g.area[i][j];
	    }
	kk++;
    }

    return sum*gamma/SQR(g.nr);
}


double volume_energy(struct geometry g, vfield n, vfield curl, sfield div /*, sfield e*/) {

    int i, j, k;
    double nvecx, nvecy, nvecz; /* vector components of n at cell center */
    double curln2; /* (curl n)^2 */
    double divn;   /* div n      */
    double ncurln; /* n . curl n */
    double sum, energy = 0.0;

    for(k = 0; k < n.nz-1; k++)
	for(j = 0; j < n.ny-1; j++)
	    for(i = g.firstcell[j]; i < n.nx-g.firstcell[j]-1; i++) {
		divn = div.v[i][j][k];

		curln2  = SQR(curl.vx[i][j][k]);
		curln2 += SQR(curl.vy[i][j][k]);
		curln2 += SQR(curl.vz[i][j][k]);

		nvecx = (n.vx[i][j][k] + n.vx[i+1][j][k]
			 + n.vx[i][j+1][k] + n.vx[i+1][j+1][k]
			 + n.vx[i][j][k+1] + n.vx[i+1][j][k+1]
			 + n.vx[i][j+1][k+1] + n.vx[i+1][j+1][k+1])/8.0;
		nvecy = (n.vy[i][j][k] + n.vy[i+1][j][k]
			 + n.vy[i][j+1][k] + n.vy[i+1][j+1][k]
			 + n.vy[i][j][k+1] + n.vy[i+1][j][k+1]
			 + n.vy[i][j+1][k+1] + n.vy[i+1][j+1][k+1])/8.0;
		nvecz = (n.vz[i][j][k] + n.vz[i+1][j][k]
			 + n.vz[i][j+1][k] + n.vz[i+1][j+1][k]
			 + n.vz[i][j][k+1] + n.vz[i+1][j][k+1]
			 + n.vz[i][j+1][k+1] + n.vz[i+1][j+1][k+1])/8.0;

		ncurln = nvecx*curl.vx[i][j][k] + nvecy*curl.vy[i][j][k]
			      + nvecz*curl.vz[i][j][k];

		sum = 16.0*curln2 + 13.0*divn*divn - 5.0*ncurln*ncurln
		    -7.74597*divn*ncurln;
/* 		e.v[i][j][k] = sum; */
		energy += sum*g.area[i][j];
	    }
    return energy*n.aspect/(13.0*g.nr*g.nr*g.nr);
}

void angles_to_xyz(const gsl_vector *angles, struct geometry geom, vfield n) {

    int i, j, k, idx = 0;
    double alpha, beta;

    for(k = 0; k < n.nz; k++)
	for(j = 0; j < n.ny; j++)
	    for(i = geom.firstnode[j]; i < n.nx-geom.firstnode[j]; i++) {
		alpha = gsl_vector_get(angles, idx);
		beta = gsl_vector_get(angles, idx+1);
		idx += 2;

		n.vx[i][j][k] = cos(alpha)*sin(beta);
		n.vy[i][j][k] = sin(alpha)*sin(beta);
		n.vz[i][j][k] = cos(beta);
	    }
}



double total_energy(struct global_data *glob) {

    double energy = 0.0;

    curl(glob->n, glob->curl);
    divergence(glob->n, glob->div);

    energy = volume_energy(glob->geom, glob->n, glob->curl, glob->div)
	+ 1.0*(surface_energy_sides(glob->geom, glob->n)
	+ surface_energy_topbot(glob->geom, glob->n));

    if(iter_flag) {
	printf("Energy: %f\n", energy);
	iter_flag = 0;
    }
    return energy;
}


double energy_f(const gsl_vector *v, void *params) {

    struct global_data *glob = (struct global_data*) params;

    angles_to_xyz(v, glob->geom, glob->n);
    return total_energy(glob);

}

void energy_fdf(const gsl_vector *v, void *params, double *f, gsl_vector *g) {

    struct global_data *glob = (struct global_data*) params;
    vfield n = glob->n;
    double e0, e1, dalpha, dbeta;
    double delta = 0.1, alpha, beta, newalpha, newbeta, oldx, oldy, oldz;
    int i, j, k, idx = 0;

    angles_to_xyz(v, glob->geom, n);
    e0 = total_energy(glob);

    for(k = 0; k < n.nz; k++)
	for(j = 0; j < n.ny; j++)
	    for(i = glob->geom.firstnode[j]; i < n.nx-glob->geom.firstnode[j]; i++) {
		alpha = gsl_vector_get(v, idx);
		beta = gsl_vector_get(v, idx+1);
		newalpha = alpha + delta;
		newbeta = beta + delta;
		oldx = n.vx[i][j][k];
		oldy = n.vy[i][j][k];
		oldz = n.vz[i][j][k];
		
		n.vx[i][j][k] = cos(newalpha)*sin(beta);
		n.vy[i][j][k] = sin(newalpha)*sin(beta);
		n.vz[i][j][k] = cos(beta);
		e1 = total_energy(glob);
		dalpha = (e1-e0);

		n.vx[i][j][k] = cos(alpha)*sin(newbeta);
		n.vy[i][j][k] = sin(alpha)*sin(newbeta);
		n.vz[i][j][k] = cos(newbeta);
		e1 = total_energy(glob);
		dbeta = (e1-e0);

		n.vx[i][j][k] = oldx;
		n.vy[i][j][k] = oldy;
		n.vz[i][j][k] = oldz;

/* 		printf("Grad %i: %e\nGrad %i: %e\n", idx,dalpha,idx+1,dbeta); */
		gsl_vector_set(g, idx, dalpha);
		gsl_vector_set(g, idx+1, dbeta);
		idx += 2;
	    }
    *f = e0;

}

void energy_df(const gsl_vector *v, void *params, gsl_vector *g) {

    double dummy = 0.0;

    energy_fdf(v, params, &dummy, g);
}


void init_nfield(vfield f) {

    int i, j, k;
    double th;

    for(i = 0; i < f.nx; i++)
	for(j = 0; j < f.ny; j++) {
	    th = atan((double) (j-.5*(f.ny-1))/(i-.5*(f.nx-1)));
/* 	    else th = pi/2.0; */
	    if(i<=f.nx/2-1) th+=pi;
	    for(k = 0; k < f.nz; k++) {
		if(i==(f.nx-1)/2&&j==(f.ny-1)/2) {
		    f.vx[i][j][k] = 0.0;
		    f.vy[i][j][k] = 0.0;
		} else {
		    f.vx[i][j][k] = -cos(th);
		    f.vy[i][j][k] = -sin(th);
		}
		if(k<f.nz/2) f.vz[i][j][k] = 1.0;
		else f.vz[i][j][k] = -1.0;
	    }
	}
}

struct global_data *get_global_data(int nr, int nz, double aspect) {

    struct global_data *g;

    g = malloc(sizeof(struct global_data));

    g->geom = get_disk_geometry(nr);
    g->n  = cyl_nfield(nr, nz, aspect);
    g->curl = cyl_vfield(nr, nz, aspect);
    g->div = cyl_sfield(nr, nz, aspect);
    g->energy_density = cyl_sfield(nr, nz, aspect);

    return g;
}


void kill_global_data(struct global_data *glob) {

    kill_geometry(glob->geom);
    kill_vfield(glob->n);
    kill_vfield(glob->curl);
    kill_sfield(glob->div);
    kill_sfield(glob->energy_density);

    free(glob);
}

#ifdef DIRECT
gsl_multimin_fminimizer *init_minimizer(struct global_data *glob) {
#else
gsl_multimin_fdfminimizer *init_minimizer(struct global_data *glob) {
#endif

#ifdef DIRECT
    gsl_multimin_fminimizer *minimizer;
    const gsl_multimin_fminimizer_type *T = gsl_multimin_fminimizer_nmsimplex;
    static gsl_multimin_function minfunc;
    gsl_vector *step_vec;
#else
    gsl_multimin_fdfminimizer *minimizer;
    const gsl_multimin_fdfminimizer_type *T = gsl_multimin_fdfminimizer_vector_bfgs;
    static gsl_multimin_function_fdf minfunc;
    double step_size = .02;
    double tol = 1e-4;
#endif
    gsl_vector *init_vec;
    size_t data_size = 2 * glob->geom.total_nodes * glob->n.nz;

    int i, j, k, idx = 0;

#ifdef DIRECT
    step_vec = gsl_vector_alloc(data_size);
    gsl_vector_set_all(step_vec, 1.0);
#endif

    init_vec = gsl_vector_alloc(data_size);

    for(k = 0; k < glob->n.nz; k++)
	for(j = 0; j < glob->n.ny; j++)
	    for(i = glob->geom.firstnode[j];
		i < glob->n.nx-glob->geom.firstnode[j]; i++) {
		gsl_vector_set(init_vec, idx, pi);
		gsl_vector_set(init_vec, idx+1, pi/2.0);
		idx += 2;
	    }

    minfunc.f = &energy_f;
#ifndef DIRECT
    minfunc.df = &energy_df;
    minfunc.fdf = &energy_fdf;
#endif
    minfunc.n = data_size;
    minfunc.params = glob;

#ifdef DIRECT
    minimizer = gsl_multimin_fminimizer_alloc(T, data_size);
    gsl_multimin_fminimizer_set(minimizer, &minfunc, init_vec, step_vec);
#else
    minimizer = gsl_multimin_fdfminimizer_alloc(T, data_size);
    gsl_multimin_fdfminimizer_set(minimizer, &minfunc, init_vec, step_size, tol);
#endif

    return minimizer;
}

#ifdef DIRECT
int do_iteration(gsl_multimin_fminimizer *min, struct global_data *glob) {
#else
int do_iteration(gsl_multimin_fdfminimizer *min, struct global_data *glob) {
#endif

    int status;
#ifdef DIRECT
    double size;
    int step2 = 1;
#endif
    int step = 1;
    gsl_vector *v;


    do {
	iter_flag = 1;
	printf("Step %i\n", step++);
#ifdef DIRECT
	status = gsl_multimin_fminimizer_iterate(min);
#else
	status = gsl_multimin_fdfminimizer_iterate(min);
#endif
	if(status)
	    printf("ERROR %i\n", status);
	else {
#ifdef DIRECT
	    size = gsl_multimin_fminimizer_size(min);
	    printf("Size: %f\n\n", size);

	    if(step >= 100*step2) {
		v = gsl_multimin_fminimizer_x(min);
#else
		v = gsl_multimin_fdfminimizer_x(min);
#endif
		angles_to_xyz(v, glob->geom, glob->n);
		dump_vfield(glob->n, "nfield.dat");

#ifdef DIRECT
		step2++;
	    }

	    status = gsl_multimin_test_size(size, 1e-2);
#else
	    status = gsl_multimin_test_gradient(min->gradient, 1e-3);
#endif
	}
    } while(status == GSL_CONTINUE);

    return status;
}



int main() {

    int nr = 5;
    int nz = 8;
    double aspect = 1.0;
    struct global_data *glob;
#ifdef DIRECT
    gsl_multimin_fminimizer *minimizer;
#else
    gsl_multimin_fdfminimizer *minimizer;
#endif

    glob = get_global_data(nr, nz, aspect);
    minimizer = init_minimizer(glob);

    do_iteration(minimizer, glob);
 
#ifdef DIRECT
    gsl_multimin_fminimizer_free(minimizer);
#else
    gsl_multimin_fdfminimizer_free(minimizer);
#endif
    kill_global_data(glob);
    return 0;
}

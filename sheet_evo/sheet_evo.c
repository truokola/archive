/*
 * Vortex sheet evolution as described in
 *    G. R. Baker, D. I. Meiron, and S. A. Orszag, J. Fluid Mech. 123, 477 (1982).
 * 
 * Version with no splines, no unclustering.
 * 
 */

#include <stdio.h>
#include <stdlib.h>
#include <math.h>
#include <time.h>


const double pi = 3.14159265358979;
const double pi2 = 6.28318530717959;

static double sqrarg;
#define SQR(a) ((sqrarg=(a)) == 0.0 ? 0.0 : sqrarg*sqrarg)

struct node {
    double x, y, de, gamma;
    double dist;
    struct node *prev, *next;
};


double *vector(int n) {

    return malloc(n * sizeof(double));
}


void swap(double **p1, double **p2) {

    double *tmp;

    tmp = *p1;
    *p1 = *p2;
    *p2 = tmp;
}


/* Calculate the first derivate d = d/de(f) of a function f of n points
   using central finite differences; f satisfies f[n] = f[0] + fper. */
void d1(double *f, double *de, double fper, int n, double *d) {

    int j;

    d[0] = (f[1] - (f[n-1]-fper))/(de[n-1]+de[0]);
    d[n-1] = ((f[0]+fper) - f[n-2])/(de[n-2]+de[n-1]);
    for(j = 1; j < n-1; j++)
	d[j] = (f[j+1] - f[j-1])/(de[j-1]+de[j]);
}

/* Calculate the second derivate d = d^2/de^2(f) of a function f of n points
   using central finite differences; f satisfies f[n] = f[0] + fper. */
void d2(double *f, double *de, double fper, int n, double *d) {

    int j;

    d[0] = 2.0*((f[1]-f[0])/de[0] - (f[0]-f[n-1]+fper)/de[n-1])/(de[n-1]+de[0]);
    d[n-1] = 2.0*((f[0]+fper-f[n-1])/de[n-1] - (f[n-1]-f[n-2])/de[n-2])/(de[n-2]+de[n-1]);
    for(j = 1; j < n-1; j++)
	d[j] = 2.0*((f[j+1]-f[j])/de[j] - (f[j]-f[j-1])/de[j-1])/(de[j-1]+de[j]);
}

double integral(double *f, double *de, int n) {

    int j;
    double sum;
    
    sum = .5*f[0]*(de[n-1]+de[0]);
    for(j = 1; j < n; j++)
	sum += .5*f[j]*(de[j-1]+de[j]);

    return sum;
}


/* Curvature c of the curve (x,y) of n points */
void calc_curvature(double *de, double *x, double *y, double *xe, double *ye, double *se,
	       int n, double *c) {

    int j;
    double *xee, *yee;  /* second derivatives */

    xee = vector(n);
    yee = vector(n);

    d2(x, de, 1.0, n, xee);
    d2(y, de, 0.0, n, yee);
    for(j = 0; j < n; j++)
	c[j] = (xe[j]*yee[j]-ye[j]*xee[j])/(se[j]*se[j]*se[j]);

    free(xee);
    free(yee);
}

void birkhoff_integral(double *de, double *x, double *y,
		       double *xe, double *ye, double *se,
		       double *gamma, double c3, int np,
		       double *vx, double *vy) {

    int j, k;
    double tmp, sumx, sumy, sini, sinr, gami, gamr, weight;

    for(j = 0; j < np; j++) {
	sumx = 0.0;
	sumy = 0.0;
	for(k = 0; k < np; k++) { /* trapezoid quadrature */
	    if(k != j) {
		tmp = .5/(cosh(pi2*(y[j]-y[k]))-cos(pi2*(x[j]-x[k])));
		sini = -sin(pi2*(x[j]-x[k])) * tmp;
		sinr = -sinh(pi2*(y[j]-y[k])) * tmp;
		gamr = gamma[k] - gamma[j]*(xe[k]*xe[j]+ye[k]*ye[j])/
		    (se[j]*se[j]);
		gami = -gamma[j]*(xe[j]*ye[k]-xe[k]*ye[j])/(se[j]*se[j]);

		if(k == 0)
		    weight = (de[np-1]+de[0])/2;
		else
		    weight = (de[k-1]+de[k])/2;
		    
		sumx += (gamr*sinr - gami*sini)*weight;
		sumy += (-gamr*sini - gami*sinr)*weight;
	    }	
	}
	vx[j] = sumx + c3;
	vy[j] = sumy;
    }
    
}

void calc_T(double *de, double *xe, double *ye,
	    double *U, int np, double *T) {

    int j;
    double *t, *te, *tu_int;
    double sum;
    
    t = vector(np);
    te = vector(np);
    tu_int = vector(np);

    for(j = 0; j < np; j++)
	t[j] = atan(ye[j]/xe[j]);
    
    d1(t, de, 0.0, np, te);

    sum = 0.0;
    for(j = 0; j < np-1; j++) {
	sum += .5*(te[j]*U[j] + te[j+1]*U[j+1])*de[j];
	tu_int[j] = sum;
    }
    sum += .5*(te[np-1]*U[np-1] + te[0]*U[0])*de[np-1];

    T[0] = 0.0;
    printf("\nT:\n0: 0.0\n");
    for(j = 1; j < np; j++) {
	T[j] = tu_int[j-1] - j/np*sum;
	printf("%i: %e\n", j, T[j]);
    }

    free(t);
    free(te);
    free(tu_int);
}



double calc_time_derivs(double *de, double *x, double *y, double *gamma,
			double c[],
			double *vx, double *vy, double *dgamma, int np) {

    int j;
    double *xe, *ye, *se, *kappa, *dgamma_pre, *T, *U, *wx, *wy;

    xe = vector(np);
    ye = vector(np);
    se = vector(np);
    kappa = vector(np);
    dgamma_pre = vector(np);
    T = vector(np);
    U = vector(np);
    wx = vector(np);
    wy = vector(np);

    d1(x, de, 1.0, np, xe);
    d1(y, de, 0.0, np, ye);
    for(j = 0; j < np; j++)
	se[j] = sqrt(xe[j]*xe[j] + ye[j]*ye[j]);

    calc_curvature(de, x, y, xe, ye, se, np, kappa);

    birkhoff_integral(de, x, y, xe, ye, se, gamma, c[3], np, wx, wy);

    printf("\nU:\n");
    for(j = 0; j < np; j++) {
	U[j] = (-ye[j]*wx[j] + xe[j]*wy[j])/se[j];
	printf("%i: %e\n", j, U[j]);
    }
    calc_T(de, xe, ye, U, np, T);

    
    for(j = 0; j < np; j++) {
	dgamma_pre[j] = 
	    + (T[j] - (wx[j]*xe[j]+wy[j]*ye[j])/se[j])*gamma[j]/se[j]
	    + c[0]*kappa[j]
	    - c[1]*U[j]
	    - c[2]*y[j];

	vx[j] = (-ye[j]*U[j] + xe[j]*T[j])/se[j];
        vy[j] = ( xe[j]*U[j] + ye[j]*T[j])/se[j];
    }

    d1(dgamma_pre, de, 0.0, np, dgamma);

    
    free(xe);
    free(ye);
    free(se);
    free(kappa);
    free(dgamma_pre);
    free(T);
    free(U);
    free(wx);
    free(wy);

    return 0.0;
}



double do_timestep(double *de, double **xp, double **yp, double **gammap,
		   double c[], int np, double dt) {

    double *x, *y, *gamma;
    double *vx, *vy, *dgamma, *x_new1, *x_new2,
	*y_new1, *y_new2, *gamma_new1, *gamma_new2;
    int j;
    double errsum, minerr;
    int nits;

    x = *xp;
    y = *yp;
    gamma = *gammap;

    vx = vector(np);
    vy = vector(np);
    dgamma = vector(np);
    x_new1 = vector(np);
    x_new2 = vector(np);
    y_new1 = vector(np);
    y_new2 = vector(np);
    gamma_new1 = vector(np);
    gamma_new2 = vector(np);
    
    calc_time_derivs(de, x, y, gamma, c, vx, vy, dgamma, np);

    for(j = 0; j < np; j++) {
	gamma_new1[j] = gamma[j] + dgamma[j]*dt;
	x_new1[j] = x[j] + vx[j]*dt;
	y_new1[j] = y[j] + vy[j]*dt;
    }

	
    minerr = 1000;
    errsum = 1000;
    nits = 0;
    while(errsum/(np*dt) > 1e-4 && nits < 6) {
	nits++;
	calc_time_derivs(de, x_new1, y_new1, gamma_new1, c,
			 vx, vy, dgamma, np);

	swap(&x_new1, &x_new2);
	swap(&y_new1, &y_new2);
	swap(&gamma_new1, &gamma_new2);

	errsum = 0.0;
	for(j = 0; j < np; j++) {
	    gamma_new1[j] = gamma[j] + dgamma[j]*dt;
	    errsum += fabs(gamma_new1[j]-gamma_new2[j]);
	    x_new1[j] = x[j] + vx[j]*dt;
	    y_new1[j] = y[j] + vy[j]*dt;
	}

	if (errsum < minerr)
	    minerr = errsum;
	else {
	    nits = 1000;
	    errsum = 0;
	}
    }

    dt *= 1.1;
    if(nits > 3) {
	dt *= .5;
/* 	printf("CONV: new dt = %.6g\n", dt); */
    } 
/* 	else  */
/* 	if(area_err > area_tol) { */
/* 	    dt *= .5; */
/* 	    area_tol *= 2; */
/* 	    printf("AREA: new dt = %.6g  (tol = %.4g)\n", dt, area_tol); */
/* 	} */

    swap(xp, &x_new1);
    swap(yp, &y_new1);
    swap(gammap, &gamma_new1);

    free(vx);
    free(vy);
    free(dgamma);
    free(x_new1);
    free(x_new2);
    free(y_new1);
    free(y_new2);
    free(gamma_new1);
    free(gamma_new2);

/*     printf("Nits: %2i\nConv: %9.5e\n", */
/* 	   nits, errsum/(np*dt)); */

    return dt;
}


void debdump(struct node *first) {
    
    struct node *p;
    int j = 1;
    double sum = 0.0;

    p = first;
    do {
	printf("Node %i: de = %f  g = %f\n", j++, p->de, p->gamma);
	sum += .5*p->gamma*(p->prev->de+p->de);
	p = p->next;
    } while(p != first);
    printf("Total err: %f\n", sum-1.0);
}


int trim_distances(double **dep, double **xp, double **yp, double **gammap,
                   double min, double max, int np) {

    int j;
    int nn = np; /* , step = 1; */
    double dist;
    double *de, *x, *y, *gamma;
    double *de_new, *x_new, *y_new, *gamma_new;
    struct node *pp, *p = NULL, *first = NULL;
    double vort1, vort2, vort3, weight;

    de = *dep;
    x = *xp;
    y = *yp;
    gamma = *gammap;

/*     printf("\n\nTotal in: %f\n", integral(gamma,de,nn)); */

    for(j = 0; j < np; j++) {
	pp = malloc(sizeof(struct node));
	pp->de = de[j];
	pp->x = x[j];
	pp->y = y[j];
	pp->gamma = gamma[j];
	if(j == np-1) {
	    dist = SQR(x[0] - x[j] + 1.0);
	    dist += SQR(y[0] - y[j]);
	} else {
	    dist = SQR(x[j+1] - x[j]);
	    dist += SQR(y[j+1] - y[j]);
	}
	pp->dist = dist;
	pp->prev = p;
	if(first == NULL)
	    first = pp;
	else
	    p->next = pp;
	p = pp;
    }
    p->next = first;
    first->prev = p;

    p = first;
    do {
/* 	printf("\n\nStep %i: ", step); */
	if(p->dist < min) {
/* 	    printf("kill\n"); */
	    vort1 = p->gamma*(p->prev->de + p->de);
	    vort2 = p->next->gamma*(p->de + p->next->de);
	    pp = p->next->next;
	    vort3 = pp->gamma*(pp->prev->de + pp->de);
	    weight = 1.0/(1.0 + p->next->de / p->de);

	    p->de += p->next->de;
	    free(p->next);
	    if(first == p->next)
		first = pp;
	    nn--;
	    p->next = pp;
	    pp->prev = p;

	    vort1 += weight*vort2;
	    vort3 += (1.0-weight)*vort2;
	    p->gamma = vort1/(p->prev->de + p->de);
	    pp->gamma = vort3/(pp->prev->de + pp->de);

	    p = pp;
	} else if(p->dist > max) {
/* 	    printf("add\n"); */
	    vort1 = p->gamma*(p->prev->de + .5*p->de);
	    vort2 = .5*p->de*(p->gamma + p->next->gamma);
	    vort3 = p->next->gamma*(.5*p->de + p->next->de);
	    
	    pp = malloc(sizeof(struct node));
	    nn++;
	    pp->de = .5*p->de;
	    p->de = pp->de;
	    pp->x = .5*(p->x + p->next->x);
	    if(first == p->next)
		pp->x += .5;
	    pp->y = .5*(p->y + p->next->y);
	    pp->next = p->next;
	    pp->prev = p;
	    pp->next->prev = pp;
	    p->next = pp;

	    p->gamma = vort1/(p->prev->de + p->de);
	    pp->gamma = vort2/(p->de + pp->de);
	    pp->next->gamma = vort3/(pp->de + pp->next->de);

	    p = pp->next;
	} else {
/* 	    printf("noop\n"); */
	    p = p->next;
	}
/* 	debdump(first); */
/* 	getchar(); */
    } while(p != first);

    de_new = vector(nn);
    x_new = vector(nn);
    y_new = vector(nn);
    gamma_new = vector(nn);

    p = first;
    j = 0;
    do {
	de_new[j] = p->de;
	x_new[j] = p->x;
	y_new[j] = p->y;
	gamma_new[j] = p->gamma;
	j++;
	pp = p;
	p = p->next;
	free(pp);
    } while(p != first);

    swap(&de_new, dep);
    swap(&x_new, xp);
    swap(&y_new, yp);
    swap(&gamma_new, gammap);

    free(de_new);
    free(x_new);
    free(y_new);
    free(gamma_new);

    return nn;
}


void fourier_smooth(double *f, int np) {

    int j;
    double sum = 0.0;
    double sign;

    sign = 1.0;
    for(j = 0; j < np; j++) {
	sum += sign*f[j];
	sign *= -1.0;
    }

    sum = sum/np;
    printf("%e\n", sum);

    sign = 1.0;
    for(j = 0; j < np; j++) {
	f[j] -= sign*sum;
	sign *= -1.0;
    }
}

double dump_data(double *de, double *x, double *y, double *gamma, int np,
		 double c[], double time, double dt, char file[]) {

    FILE *dump;
    int j;
    char tmp[30];
    double max = -100.0;
    double min =  100.0;

    sprintf(tmp, "%s.tmp", file);
    dump = fopen(tmp, "w");
    fprintf(dump, "# t  = %f\n", time);
    fprintf(dump, "# n  = %i\n", np);
    fprintf(dump, "# dt = %f\n", dt);
    fprintf(dump, "# c0 = %f\n", c[0]);
    fprintf(dump, "# c1 = %f\n", c[1]);
    fprintf(dump, "# c2 = %f\n", c[2]);
    fprintf(dump, "# c3 = %f\n", c[3]);
    for(j = 0; j < np; j++) {
	fprintf(dump, "%.6g\t%.6g\t%.6g\t%.6g\n",
		x[j], y[j], gamma[j], de[j]);
	if(y[j] > max)
	    max = y[j];
	else if(y[j] < min)
	    min = y[j];
    }
    fclose(dump);
    rename(tmp, file);
    return max-min;
}

void init_sheet(double *de, double *x, double *y, double *gamma,
		int np, double velodiff) {

    int j;

    for(j = 0; j < np; j++) {
	de[j] = 1.0/np;
	x[j] = (double) j/np;/* + 0.01*sin(pi2*j/np);*/
/* 	y[j] = .01*exp(-.05*(j-np/2)*(j-np/2)); */
	y[j] = .0*sin(pi2*j/np);
	gamma[j] = velodiff;/*1+sin(6.0*pi*j/np);*/
    }
}



void get_physical_params(double c[]) {
    
    double
/* 	sigma = 22.93e-9, */
/* 	Gamma = 0, */
/* 	Gamma = 300e-3, */
/* 	F = 15.25, */
/* 	rho = 86.9, */
/* 	v1 = 4.5e-3, */
/* 	v2 = 0.0, */
/* 	L = 244e-6, */
/* 	gbar = v1-v2, */
/* 	v_ave = .5*(v1+v2), */
	We, Ri, Gp,
	l0, Gt, v;

/*     We = rho*gbar*gbar*L/sigma; */
/*     Ri = F*L/(rho*gbar*gbar); */
/*     Gp = Gamma/(rho*gbar); */

/*     We = 20; */
/*     Ri = 2; */
/*     Gp = 1; */

    l0 = 1.00;      /* 2pi/k0, in units of L */
    Gt = 2.00;      /* Gamma, in units of rho*v_c */
    v  = 1.25;      /* in units of v_c */

    We = 4.0*pi*v*v/l0;
    Ri = pi/(v*v*l0);
    Gp = Gt/v;
    
    c[0] = 1.0/We;
    c[1] = Gp;
    c[2] = Ri;
    c[3] = .5;

/*     c[0] = .25*l0/pi; */
/*     c[1] = Gt; */
/*     c[2] = pi/l0; */
/*     c[3] = .5*v; */


}


int main() {

    int np = 9; /* number of points on the sheet */
    double dt = .005;
    int step = 0;
    double time = 0.0;
    double *de, *x, *y, *gamma;
    double c[4];
/*     int j; */
/*     double sumg; */
    char fname[30];
    int dump_num = 0;
    double dump_time = 1;
/*     double max; */
/*     double sum; */
/*     FILE *dump; */
/*     double mindist = SQR(.5/np); */
/*     double maxdist = SQR(1.5/np); */


    get_physical_params(c);

    de = vector(np);
    x = vector(np);
    y = vector(np);
    gamma = vector(np);

    init_sheet(de, x, y, gamma, np, 2.0*c[3]);
    
/*     getchar(); */



/*     dump = fopen("max2.dat", "w"); */

    while(1) {
	
	if(time >= dump_time * dump_num) {
	    sprintf(fname, "sheet_%03i.dat", dump_num);
	    dump_data(de, x, y, gamma, np, c, time, dt, fname);
	    dump_num++;
	}

	step++;
	time += dt;

	/*printf("\x1B[2J");*/
/*	printf("****  ");*/
/* 	printf("Step: %5i    Time: %8.5f (%8.5f s)   (dt = %9.4g)\n", */
/* 	       step, time, realtime, dt); */
/*	printf("  *****\n");*/

/* 	printf("Gamma before step:\t%f\n", integral(gamma,de,np)-1.0); */
	dt = do_timestep(de, &x, &y, &gamma, c, np, dt);

/* 	printf("Gamma before trim:\t%f\n", integral(gamma,de,np)-1.0); */
/* 	np = trim_distances(&de, &x, &y, &gamma, mindist, maxdist, np); */
/* 	printf("Gamma after (%i):\t%f\n\n", np,integral(gamma,de,np)-1.0); */

/* 	printf("Smooth x: "); */
/* 	fourier_smooth(x, np); */
/* 	printf("Smooth y: "); */
/* 	fourier_smooth(y, np); */

/* 	sum = integral(gamma,de,np)-1.0; */
/* 	if(fabs(sum) > 1e-12) { */
/* 	    printf("Step: %i   Gamma: %e\n", step, sum); */
/* 	    getchar(); */
/* 	} */
/* 	getchar(); */
/* 	sumg = 0.0; */
/* 	for(j = 0; j < np; j++) */
/* 	    sumg += gamma[j]*de[j]; */

/* 	printf("np: %3i\nSum g: %9.5e\n", np, sumg-1); */

/* 	max = dump_data(x, y, gamma, np, "sheet2.dat"); */
/* 	fprintf(dump, "%f\t%f\n", realtime, max); */
/* 	getchar(); */
 	
    }
/*     fclose(dump); */

    return 0;
}

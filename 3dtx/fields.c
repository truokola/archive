#include <stdio.h>
#include <stdlib.h>
#include <math.h>
#include "matvec.h"
#include "fields.h"

#define MIN(a,b) (a < b ? a : b)

sfield cyl_sfield(int nr, int nz, double aspect) {

    sfield f;

    f.nx = 2*nr;
    f.ny = 2*nr;
    f.nz = nz;
    f.aspect = aspect;
    f.offset = 0.5;
    f.v = grid3(f.nx,f.ny,f.nz);

    return f;
}

void kill_sfield(sfield f) {

    kill_grid3(f.v, f.nx, f.ny);
}

vfield cyl_vfield(int nr, int nz, double aspect) {

    vfield f;

    f.nx = 2*nr;
    f.ny = 2*nr;
    f.nz = nz;
    f.aspect = aspect;
    f.offset = 0.5;
    f.vx = grid3(f.nx,f.ny,f.nz);
    f.vy = grid3(f.nx,f.ny,f.nz);
    f.vz = grid3(f.nx,f.ny,f.nz);

    return f;
}


vfield cyl_nfield(int nr, int nz, double aspect) {

    vfield f;

    f.nx = 2*nr+1;
    f.ny = 2*nr+1;
    f.nz = nz+1;
    f.aspect = aspect;
    f.offset = 0.0;
    f.vx = grid3(f.nx,f.ny,f.nz);
    f.vy = grid3(f.nx,f.ny,f.nz);
    f.vz = grid3(f.nx,f.ny,f.nz);

    return f;
}


void kill_vfield(vfield f) {

    kill_grid3(f.vx, f.nx, f.ny);
    kill_grid3(f.vy, f.nx, f.ny);
    kill_grid3(f.vz, f.nx, f.ny);
}


struct geometry get_disk_geometry(int nr) {

    struct geometry g;
    double R = (double) nr;
    double x0, y0;
    int i, j;
    double x1, x2, y1, y2, xc, yc, xfloor, yceil;
    double a;
    double dx, dy, len;
    struct bnode *curnode = NULL, *prevnode = NULL, *innode;
    int chainlen = 0;
    
    g.nr = nr;
    g.area = matrix(2*nr, 2*nr);
    g.firstcell = ivector(2*nr);
    g.firstnode = ivector(2*nr+1);
    g.total_nodes = 0;
    g.boundary = NULL;

    for(j = 0; j < 2*nr; j++)
	for(i = 0; i < 2*nr; i++)
	    g.area[i][j] = -100.0;
 
    x0 = 0.0;
    y0 = R - 1.0;
    i = nr;
    j = 2*nr-1;
    
	
    /* Traverse the first quadrant of the circle */
    while(j >= nr) {

	/* First intersection point of cell and circle */
	yceil = sqrt(R*R - x0*x0) - y0;
	if(yceil <= 1.0) {
	    x1 = 0.0;
	    y1 = yceil;
	} else {
	    x1 = sqrt(R*R - (y0+1.0)*(y0+1.0)) - x0;
	    y1 = 1.0;
	}

	/* Second intersection point of cell and circle */
	xfloor = sqrt(R*R - y0*y0) - x0;
	if(xfloor <= 1.0) {
	    x2 = xfloor;
	    y2 = 0.0;
	} else {
	    x2 = 1.0;
	    y2 = sqrt(R*R - (x0+1.0)*(x0+1.0)) - y0;
	}

	dx = x2 - x1;
	dy = y1 - y2;

	/* Area of disk segment inside the cell */
	a = x1 + (1.0-x1)*y2 + .5*dx*dy;

/* 	printf("(%i, %i)  \t%f, %f  (%f)\n", i-nr,j-nr,x1,y1,a); */
	g.area[i][j] = a;
	g.area[j][2*nr-i-1] = a;
	g.area[2*nr-i-1][2*nr-j-1] = a;
	g.area[2*nr-j-1][i] = a;

	len = sqrt(dx*dx + dy*dy);

	/* Put boundary cells in a linked list,        */
	/* excluding those which only touch the circle */
	if(len > 0.0) {
	    curnode = malloc(sizeof(struct bnode));
	    curnode->i = i;
	    curnode->j = j;
	    curnode->seglen = len;
	    curnode->normx = -dy/len;
	    curnode->normy = -dx/len;

	    xc = .5*(x1+x2);
	    yc = .5*(y1+y2);
	    curnode->w1 = (1.0-xc)*(1.0-yc);
	    curnode->w2 = xc*(1.0-yc);
	    curnode->w3 = (1.0-xc)*yc;
	    curnode->w4 = xc*yc;

	    if(g.boundary == NULL)
		g.boundary = curnode;
	    else
		prevnode->next = curnode;
	    prevnode = curnode;
	    chainlen++;
	}

	/* Determine the next cell along the circle */
	if(xfloor <= 1.0) {
	    g.firstcell[j] = 2*nr-i-1;
	    g.firstcell[2*nr-j-1] = g.firstcell[j];
	    j--;
	    y0 -= 1.0;
	} else {
	    i++;
	    x0 += 1.0;
	}

    }


    /* Fill the interior cells */
    for(j = 0; j < 2*nr; j++)
	for(i = g.firstcell[j]+1; i < 2*nr-g.firstcell[j]-1; i++)
	    if(g.area[i][j] < 0.0)
		g.area[i][j] = 1.0;

    /* Determine first nodes based on first cells on each row */
    for(j = 0; j <= 2*nr; j++) {
	if(j == 0)
	    g.firstnode[0] = g.firstcell[0];
	else if (j == 2*nr)
	    g.firstnode[2*nr] = g.firstcell[2*nr-1];
	else
	    g.firstnode[j] = MIN(g.firstcell[j], g.firstcell[j-1]);

	g.total_nodes += 2*(nr-g.firstnode[j]) + 1;
    }

    /* Boundary cells in the 4th quadrant */
    innode = g.boundary;
    for(i=1; i <= chainlen; i++) {
	curnode = malloc(sizeof(struct bnode));
	curnode->i = innode->j;
	curnode->j = 2*nr-1-innode->i;
	curnode->seglen = innode->seglen;
	curnode->normx = innode->normy;
	curnode->normy = -innode->normx;
	curnode->w1 = innode->w2;
	curnode->w2 = innode->w4;
	curnode->w3 = innode->w1;
	curnode->w4 = innode->w3;

	prevnode->next = curnode;
	prevnode = curnode;
	innode = innode->next;
    }

    /* Q3 */
    innode = g.boundary;
    for(i=1; i <= chainlen; i++) {
	curnode = malloc(sizeof(struct bnode));
	curnode->i = 2*nr-1-innode->i;
	curnode->j = 2*nr-1-innode->j;
	curnode->seglen = innode->seglen;
	curnode->normx = -innode->normx;
	curnode->normy = -innode->normy;
	curnode->w1 = innode->w4;
	curnode->w2 = innode->w3;
	curnode->w3 = innode->w2;
	curnode->w4 = innode->w1;

	prevnode->next = curnode;
	prevnode = curnode;
	innode = innode->next;
    }

    /* Q2 */
    innode = g.boundary;
    for(i=1; i <= chainlen; i++) {
	curnode = malloc(sizeof(struct bnode));
	curnode->i = 2*nr-1-innode->j;
	curnode->j = innode->i;
	curnode->seglen = innode->seglen;
	curnode->normx = -innode->normy;
	curnode->normy = innode->normx;
	curnode->w1 = innode->w3;
	curnode->w2 = innode->w1;
	curnode->w3 = innode->w4;
	curnode->w4 = innode->w2;

	prevnode->next = curnode;
	prevnode = curnode;
	innode = innode->next;
    }

    curnode->next = NULL;

    return g;
}

void kill_geometry(struct geometry geom) {
    
    struct bnode *node, *next;

    kill_matrix(geom.area, 2*geom.nr);
    kill_ivector(geom.firstcell);
    kill_ivector(geom.firstnode);

    node = geom.boundary;
    while(node != NULL) {
	next = node->next;
	free(node);
	node = next;
    }
}

void dump_sfield(sfield f, char file[]) {

    int i, j, k;
    FILE *dump;
    char tmp[100];

    sprintf(tmp, "%s.tmp", file);
    dump = fopen(tmp, "w");
    for(i = 0; i < f.nx; i++)
	for(j = 0; j < f.ny; j++)
	    for(k = 0; k < f.nz; k++)
		fprintf(dump, "%f\t%f\t%f\t%f\n",
			f.offset+i, f.offset+j, f.aspect*(f.offset+k), f.v[i][j][k]);

    fclose(dump);
    rename(tmp, file);

}

void dump_vfield(vfield f, char file[]) {

    int i, j, k;
    FILE *dump;
    char tmp[100];

    sprintf(tmp, "%s.tmp", file);
    dump = fopen(tmp, "w");
    for(i = 0; i < f.nx; i++)
	for(j = 0; j < f.ny; j++)
	    for(k = 0; k < f.nz; k++)
		fprintf(dump, "%f\t%f\t%f\t%f\t%f\t%f\n",
			f.offset+i, f.offset+j, f.aspect*(f.offset+k),
			f.vx[i][j][k], f.vy[i][j][k], f.vz[i][j][k]);

    fclose(dump);
    rename(tmp, file);

}


void divergence(vfield f, sfield resf) {

    int i, j, k;
    double div;

    for(i = 0; i < f.nx-1; i++)
	for(j = 0; j < f.ny-1; j++)
	    for(k = 0; k < f.nz-1; k++) {
		/* 4*dvx/dx */
		div = f.vx[i+1][j][k]+f.vx[i+1][j+1][k]+f.vx[i+1][j][k+1]+f.vx[i+1][j+1][k+1]
			   -f.vx[i][j][k]-f.vx[i][j+1][k]-f.vx[i][j][k+1]-f.vx[i][j+1][k+1];
		/* 4*dvy/dy */
		div += f.vy[i][j+1][k]+f.vy[i+1][j+1][k]+f.vy[i][j+1][k+1]+f.vy[i+1][j+1][k+1]
		    -f.vy[i][j][k]-f.vy[i+1][j][k]-f.vy[i][j][k+1]-f.vy[i+1][j][k+1];
		/* 4*dvz/dz */
		div += (f.vz[i][j][k+1]+f.vz[i+1][j][k+1]+f.vz[i][j+1][k+1]+f.vz[i+1][j+1][k+1]
			-f.vz[i][j][k]-f.vz[i+1][j][k]-f.vz[i][j+1][k]-f.vz[i+1][j+1][k])/f.aspect;
		div *= .25;
		resf.v[i][j][k] = div;
	    }
}

		
void curl(vfield f, vfield resf) {

    int i, j, k;
    double comp, prevcomp = 0.0;

    /* x component of curl */
    for(j = 0; j < f.ny-1; j++)
	for(k = 0; k < f.nz-1; k++)
	    for(i = 0; i < f.nx; i++) {
		/* -2*dvy/dz */
		comp = (-f.vy[i][j][k+1] - f.vy[i][j+1][k+1]
			+ f.vy[i][j][k] + f.vy[i][j+1][k])/f.aspect;
		/* 2*dvz/dy */
		comp += f.vz[i][j+1][k] + f.vz[i][j+1][k+1]
		    -f.vz[i][j][k] - f.vz[i][j][k+1];
		if(i > 0)
		    resf.vx[i-1][j][k] = .25*(prevcomp+comp);
		prevcomp = comp;
	    }


    /* y component of curl */
    for(i = 0; i < f.nx-1; i++)
    	for(k = 0; k < f.nz-1; k++)
	    for(j = 0; j < f.ny; j++) {
		/* 2*dvx/dz */
		comp = (f.vx[i][j][k+1] + f.vx[i+1][j][k+1]
			-f.vx[i][j][k] - f.vx[i+1][j][k])/f.aspect;
		/* -2*dvz/dx */
		comp += -f.vz[i+1][j][k] - f.vz[i+1][j][k+1]
		    + f.vz[i][j][k] + f.vz[i][j][k+1];
		if(j > 0)
		    resf.vy[i][j-1][k] = .25*(prevcomp+comp);
		prevcomp = comp;
	    }
    


    /* z component of curl */
    for(i = 0; i < f.nx-1; i++)
	for(j = 0; j < f.ny-1; j++)
	    for(k = 0; k < f.nz; k++) {
		/* -2*dvx/dy */
		comp = -f.vx[i][j+1][k] - f.vx[i+1][j+1][k]
		    + f.vx[i][j][k] + f.vx[i+1][j][k];
		/* 2*dvy/dx */
		comp += f.vy[i+1][j][k] + f.vy[i+1][j+1][k]
		    -f.vy[i][j][k] - f.vy[i][j+1][k];
		if(k > 0)
		    resf.vz[i][j][k-1] = .25*(prevcomp+comp);
		prevcomp = comp;
	    }
    
}

double volume_integral(struct geometry g, sfield f) {

    int i, j, k;
    double sum = 0.0;

    for(k = 0; k < f.nz; k++)
	for(j = 0; j < f.ny; j++)
	    for(i = g.firstcell[j]; i < f.nx-g.firstcell[j]; i++)
		sum += g.area[i][j] * f.v[i][j][k];

    return sum*f.aspect;
}


#include <srgp.h>


typedef struct{
  double x, y;
} dpoint;



/* Ruudulla olevan kuvion yksilöivä rakenne */

struct picture_info{
  rectangle area;             /* Kuva-alue ikkunassa                    */
  int       is_mandel,        /* Onko kuvio Mandelbrot vai Julia        */
            max_iterations;   /* Maksimi iteraatiomäärä                 */
  dpoint    orig,             /* Vas. alakulmassa olevan joukon pisteen */ 
                              /* koordinaatit                           */ 
            julia_c;          /* Julia-iteraation vakio                 */
  double    scale;            /* Pituus joukon koordinaatistossa /      */
                              /* pituus pikseleissä                     */
};

typedef struct picture_info *infoptr;



dpoint to_dpoint(point, infoptr);
point to_point(dpoint, infoptr);
void init_coords(infoptr);
void fit_region(infoptr, double, double);
int iterate(dpoint, dpoint, int);
int select_color(int, int);
dpoint c_sqrt(dpoint);
rectangle get_prev_rect(infoptr);


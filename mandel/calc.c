#include <math.h>
#include <stdlib.h>
#include "calc.h"

/*************************************************/
/*                                               */
/*  Mandelbrot-ohjelman laskenta-apufunktioita   */
/*                                               */
/*************************************************/



/* Muuntaa ikkunan pikselikoordinaatit infoptrin osoittaman
   joukon koordinaateiksi. */

dpoint to_dpoint(point arg, infoptr pic)
{
  dpoint res;
  res.x = (arg.x - pic->area.bottom_left.x) * pic->scale + pic->orig.x;
  res.y = (arg.y - pic->area.bottom_left.y) * pic->scale + pic->orig.y;
  return res;
}



/* Muuntaa joukon koordinaatit ikkunan koordinaateiksi. */

point to_point(dpoint arg, infoptr pic)
{
  point res;
  res.x = (arg.x - pic->orig.x) / pic->scale + pic->area.bottom_left.x;
  res.y = (arg.y - pic->orig.y) / pic->scale + pic->area.bottom_left.y;
  return res;
}



/* Alustaa koordinaatit, kun kuvio näytetään ensimmäistä kertaa */

void init_coords(infoptr pic)
{
  pic->orig.x = pic->orig.y = -2;  /* Vas. alakulmassa on piste z = -2-2i. */
  fit_region(pic, 4, 4);      /* Sovitetaan ikkunaan alue, jonka leveys ja */
                              /* korkeus on 4 yksikköä, eli kompleksialue  */
                              /* (-2-2i) - (2+2i).                         */
  pic->max_iterations = 20;   /* Aluksi aina max. 20 iteraatiota.          */
}



/* Mitoittaa zoomauksen siten, että kompleksialue kooltaan w*h täyttää
   koko kuva-alan. */

void fit_region(infoptr pic, double w, double h)
{
  double scale_x, scale_y;
  scale_x = w / (pic->area.top_right.x - pic->area.bottom_left.x);
  scale_y = h / (pic->area.top_right.y - pic->area.bottom_left.y);
   
  /* Valitaan siten, että alue sopii ruudulle kokonaan */
  pic->scale = (scale_x > scale_y)? scale_x : scale_y; 
}



/* Iteroi z[n+1]=z[n]^2 + increment, kunnes |z|>2 eli x^2+y^2>4 tai max_iter täyttyy.
   Palauttaa iteraatiomäärän. */

int iterate(dpoint initial, dpoint increment, int max_iter)
{
  double x, y, tmp;
  int n=0;
  x=initial.x;
  y=initial.y;  

  while((n<max_iter) && (x*x+y*y < 4))
  {
    tmp = x*x - y*y + increment.x;
    y   = 2*x*y + increment.y;
    x   = tmp;
    n++;
  }

  return n;
}



/* Valitsee värin 1-15 pisteelle, joka hajaantuu n iteraatiokerralla */

int select_color(int n, int max_iter)
{
  int color;
  if(n==max_iter)
    color = SRGP_BLACK; /* Joukkoon kuuluvat pisteet ovat mustia */
  else
    color = (double) n / max_iter * 15 + 1; /* Jaetaan alue 0..max_iter-1 */
					    /* 15 yhtä pitkään väliin.    */
  return color;
}



/* Palauttaa kompleksiluvun arg neliöjuuren. */

dpoint c_sqrt(dpoint arg)
{
  dpoint res;
  res.x = sqrt((arg.x + sqrt(arg.x*arg.x + arg.y*arg.y)) / 2);

  if((random() & 1) == 0)   /* Arvotaan 0 tai 1 ja valitaan    */
    res.x = -res.x;         /* sen perusteella toinen juurista */

  if(res.x != 0)
    res.y = arg.y / (2*res.x);
  else
    res.y = sqrt(-arg.x);

  return res;
}



/* Palauttaa ikkunan oikeassa yläkulmassa sijaitsevan neliön, jonka sivu on
   kolmasosa ikkunan lyhyemmästä sivusta.
   Tätä käytetään Julia preview -ruutuna. */

rectangle get_prev_rect(infoptr pic)
{
  int width, height, side;
  rectangle prev_rect;

  width  = pic->area.top_right.x - pic->area.bottom_left.x;
  height = pic->area.top_right.y - pic->area.bottom_left.y;
  side = (width < height)? width / 3 : height / 3;
  prev_rect.top_right = pic->area.top_right;
  prev_rect.bottom_left.x = prev_rect.top_right.x - side;
  prev_rect.bottom_left.y = prev_rect.top_right.y - side;
  return prev_rect;
}


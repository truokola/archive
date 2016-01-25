#include <stdio.h>
#include <stdlib.h>
#include "calc.h"

#define JULIA_LIMIT 1000    /* julia previewin pisteiden määrä */


/********************************************/
/*                                          */
/*   Mandelbrot-ohjelman grafiikkafuntiot   */
/*                                          */
/********************************************/




/* Piirtää kuviosta suorakulmion area rajaaman alueen uudelleen. */

void repaint(infoptr pic, rectangle area)
{
  point p;
  int n;

  for(p.y = area.bottom_left.y; p.y <= area.top_right.y; p.y++)
    for(p.x = area.bottom_left.x; p.x <= area.top_right.x; p.x++)
    { 
      /* Muutetaan pikselikoordinaatit joukon koordinaateiksi ja iteroidaan */
      if(pic->is_mandel)    /* Mandelbrotin joukko */
	n = iterate(to_dpoint(p, pic),     /* alkupiste  */
		    to_dpoint(p, pic),     /* iteraation lisäys */
		    pic->max_iterations);  /* max iteraatiot */

      else   /* Julian joukko */
	n = iterate(to_dpoint(p, pic),
		    pic->julia_c,
		    pic->max_iterations);

      /* Pikselin väri hajaantumisnopeuden n mukaan */
      SRGP_setColor(select_color(n, pic->max_iterations));
      SRGP_point(p);
    }
}



/* Zoomataan kuva siten, että pisteiden rajaama suorakulmio täyttää ikkunan
   ja sen vasen alakulma on ikkunan vasemmassa alakulmassa. */

void zoom_in(infoptr pic, point corner1, point corner2)
{
  int width, height;
  point bottom_left;
  width  = abs(corner2.x - corner1.x);
  height = abs(corner2.y - corner1.y);
  bottom_left.x = (corner1.x < corner2.x)? corner1.x : corner2.x;
  bottom_left.y = (corner1.y < corner2.y)? corner1.y : corner2.y;

  if((width!=0) || (height!=0))    /* Ei ääretöntä zoomausta */
  {  
    /* Siirretään origo ja zoomataan */
    pic->orig = to_dpoint(bottom_left, pic);
    fit_region(pic, width * pic->scale, height * pic->scale);
    repaint(pic, pic->area);
  }
}



/* Siirtää kuvaa vaakatasossa muuttamatta zoomausta */

void slide(infoptr pic, point from, point to)
{
  pic->orig.x += (from.x - to.x) * pic->scale;
  pic->orig.y += (from.y - to.y) * pic->scale;
  repaint(pic, pic->area);
}



/* Vaihtaa kuvaa Mandelbrotin ja Julian joukkojen välillä */

void change_set(infoptr pic, point julia_pos) /* julia_pos=hiiren klikkauspiste */
{
  if(pic->is_mandel)  /* Mandelbrot -> Julia */
  {
    pic->is_mandel = FALSE;
    pic->julia_c = to_dpoint(julia_pos, pic);
    init_coords(pic);
    repaint(pic, pic->area);
  }
  else                /* Julia -> Mandelbrot */
  {
    pic->is_mandel = TRUE;
    init_coords(pic);
    repaint(pic, pic->area);
  }
}



/* Tulostaa alueen box sisään sen joukon pisteen koordinaatit, jonka
   päällä hiiriosoitin on. */

void print_coords(infoptr pic, point mouse_pos, rectangle box)
{
  char coord_string[20];
  dpoint coords;

  /* Peitetään vanha teksti */
  SRGP_setColor(SRGP_BLACK);
  SRGP_fillRectangle(box);
  
  /* Muotoillaan uusi teksti */
  coords = to_dpoint(mouse_pos, pic);
  sprintf(coord_string, "(%.17f, %.17f)", coords.x, coords.y);
  SRGP_setColor(SRGP_WHITE);
  SRGP_setClipRectangle(box); /* Varmistetaan ettei teksti ylitä rajoja */
  SRGP_text(box.bottom_left, coord_string);
  SRGP_setClipRectangle(pic->area);
}



/* Piirtää ikkunan oikeaan yläkulmaan Julia preview -ruudun, johon inverse 
   function -tekniikalla piirretään hiiren sijaintia vastaava Julian joukko. */

void paint_julia_prev(infoptr pic, point mouse_pos)
{
  struct picture_info prev_pic;
  dpoint p, tmp;
  int n = 0;

  prev_pic.area = get_prev_rect(pic);
  init_coords(&prev_pic);    /* Asetetaan sopiva skaalaus */
  /* Julia-vakio hiiren koordinaateista */  
  prev_pic.julia_c = to_dpoint(mouse_pos, pic); 
  SRGP_setClipRectangle(prev_pic.area);
  SRGP_setColor(SRGP_BLACK);  /* Peitetään vanha kuva */
  SRGP_fillRectangleCoord(prev_pic.area.bottom_left.x + 1,
			  prev_pic.area.bottom_left.y + 1,
			  prev_pic.area.top_right.x - 1,
			  prev_pic.area.top_right.y - 1); 
  SRGP_setColor(SRGP_WHITE);  /* Valkea reunus */
  SRGP_rectangle(prev_pic.area);
  p.x = 0;   /* Inverse functionin */
  p.y = 0;   /* alkupiste          */

  while(n < JULIA_LIMIT)
  {   /*  z[n+1] = sqrt(z[n] - c)  */
    tmp.x = p.x - prev_pic.julia_c.x;
    tmp.y = p.y - prev_pic.julia_c.y;
    p = c_sqrt(tmp);
    SRGP_point(to_point(p, &prev_pic));
    n++;
  }
  SRGP_setClipRectangle(pic->area);
}
    



#include <stdio.h>
#include <stdlib.h>
#include "calc.h"
#include "graph.h"

#define INIT_W 400
#define INIT_H 400
#define INPUT_BUFFER_LEN 6


/*************************************************************/
/*                                                           */
/*   Ohjelma Mandelbrotin ja Julian joukkojen tarkasteluun   */
/*                                                           */
/*************************************************************/


struct picture_info picture;



/* X kutsuu tätä, kun käyttäjä muuttaa ikkunan kokoa. Muuttaa clipping 
   rectanglen ja oikeat arvot "sisäiseen kirjanpitoon". Tämän takia 
   picture on jouduttu valitsemaan globaaliksi muuttujaksi. */
 
int resize_callback(int neww, int newh)
{  
  picture.area.top_right.x = neww;
  picture.area.top_right.y = newh;
  SRGP_setClipRectangle(picture.area);
  repaint(&picture, picture.area);
  return 0;
}



/* Alustaa väripaletin värit 2-15 */

void init_colors()
{
  unsigned short r[14]={0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x2000, 0x3800,
                        0x5000, 0x6800, 0x8000, 0x9800, 0xB000, 0xC800, 0xE000},

                 g[14]={0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000,
                        0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000},

                 b[14]={0x2000, 0x3800, 0x5000, 0x6800, 0x8000, 0x9800, 0xB000,
                        0xC800, 0xE000, 0x9000, 0x5000, 0x1000, 0x0000, 0x0000};

  SRGP_loadColorTable(2, 14, r, g, b);
}



/* Kysyy käyttäjältä uutta iteraatiomaksimia ja palauttaa syötetyn arvon tai
   oletusarvon jos syöte on virheellinen. 
   Suurin palautettava arvo on 99999 (5 merkkiä=INPUT_BUFFER_LEN-1) ja pienin 1. */

int input_value(rectangle textrect, int defvalue)
{
  char buffer[INPUT_BUFFER_LEN],
       prompt[30];
  int value, 
      prompt_width, dummy;
  point echo_origin;

  sprintf(prompt, "Max iterations (%d): ", defvalue);
  SRGP_setColor(SRGP_WHITE);
  SRGP_fillRectangle(textrect);
  SRGP_setColor(SRGP_BLACK);
  SRGP_text(textrect.bottom_left, prompt);
  SRGP_inquireTextExtent(prompt, &prompt_width, &dummy, &dummy); /* Syöttöalue      */
  echo_origin.x = textrect.bottom_left.x + prompt_width;         /* alkaa kehote-   */
  echo_origin.y = textrect.bottom_left.y;                        /* tekstin jälkeen */
  SRGP_setInputMode(LOCATOR, INACTIVE);     /* Hiiri "pois päältä" */
  SRGP_setKeyboardEchoOrigin(echo_origin);
  SRGP_setKeyboardProcessingMode(EDIT);
 
  SRGP_waitEvent(-1);   /* Odotetaan ENTERiä */

  SRGP_getKeyboard(buffer, INPUT_BUFFER_LEN);
  SRGP_setKeyboardProcessingMode(RAW);  /* Palautetaan      */
  SRGP_setInputMode(LOCATOR, SAMPLE);   /* normaalit moodit */

  value = atoi(buffer);
  if(value<1) value = defvalue;
  return value;
}



/* Pääsilmukka, käsittelee hiiri- ja näppäimistösyötteet */

void process_input()
{
  inputDevice dev;
  locator_measure meas;
  deluxe_keyboard_measure kbd_meas;
  char key_pressed[2]={'\0'}; 
  point startpos,lastpos;
  int dragging    = 0,       /* 1=zoomaus, 2=raahaus */
      show_coords = FALSE,   /* näytetäänkö koordinaatit */
      show_prev   = FALSE;   /* näytetäänkö julia preview */
  rectangle textbox;         /* koordinaattitekstiruutu */
  int dummy;

  SRGP_setInputMode(LOCATOR, SAMPLE);
  SRGP_setKeyboardProcessingMode(RAW);
  SRGP_setInputMode(KEYBOARD, EVENT);
  kbd_meas.buffer = key_pressed;
  kbd_meas.buffer_length = 2;

  textbox.bottom_left.x = textbox.bottom_left.y = 0;
  /* Varataan tilaa 17 desimaalille. Suuremmilla tarkkuuksilla käyttö ei enää ole 
     mielekästä, koska kuvasta tulee palikkamainen doublen tarkkuuden loppuessa. */
  SRGP_inquireTextExtent("(-0.00000000000000000, -0.00000000000000000)",
			 &textbox.top_right.x, &textbox.top_right.y, &dummy);

  while (key_pressed[0]!='\030') /* Ctrl-x lopettaa */
  {
    dev = SRGP_waitEvent(0); /* Tarkistetaan näppäinpuskuri */
    if(dev == KEYBOARD)
    {
      SRGP_getDeluxeKeyboard(&kbd_meas);

      /* 'c' vaihtaa koordinaattinäytön päälle/pois */ 
      if(key_pressed[0]=='c')
      {
	if(show_coords)
        {
	  show_coords = FALSE;
	  /* Maalataan uudelleen vain tekstiruudun peittämä alue */
   	  repaint(&picture, textbox);
        }
        else
        {
	  show_coords = TRUE;
	  print_coords(&picture, kbd_meas.position, textbox);
	  SRGP_refresh();
        }
      }
       
      /* 'z' zoomaa ulos pienetämällä zoomauskertoimen kolmasosaan */
      else if((key_pressed[0]=='z') && (dragging==0))
      {
	picture.scale *= 3;
	repaint(&picture, picture.area);
      }

      /* 'i' kysyy käyttäjältä uutta iteraatiomaksimia */
      else if((key_pressed[0]=='i') && (dragging==0))
      {
	picture.max_iterations = input_value(
	  /* Syöttörivi tekstin korkuinen ja koko ikkunan levyinen */
	  SRGP_defRectangle(0, 0, picture.area.top_right.x, textbox.top_right.y),
	  picture.max_iterations);                               
	repaint(&picture, picture.area);
      }

      /* 'j' asettaa tai poistaa julia preview -ruudun */
      else if((key_pressed[0]=='j') && (picture.is_mandel==TRUE))
      {
	if(show_prev)
	{
	  show_prev = FALSE;  
	  /* Maalataan esikatselun peittämä alue uudelleen */
	  repaint(&picture, get_prev_rect(&picture));  
	}
	else
	{
	  show_prev = TRUE;
	  paint_julia_prev(&picture, kbd_meas.position);
	}
      }
    }  
 
    
    SRGP_sampleLocator(&meas); /* Luetaan hiirtä */
  
    /* Keskinappi vaihtaa Julian ja Mandelbrotin välillä */
    if ((meas.button_chord[MIDDLE_BUTTON] == DOWN) && (dragging == 0))
      change_set(&picture, meas.position);
 

    if (meas.button_chord[LEFT_BUTTON] == DOWN) 
    {
      if (dragging == 0)  /* zoomaus aloitetaan, asetetaan suorakulmiokursori */
      {
        dragging = 1; 
        startpos = meas.position;
	SRGP_setLocatorEchoType(RUBBER_RECT);
	SRGP_setLocatorEchoRubberAnchor(startpos);
      }
    }
    else if(dragging==1)  /* vasen vapautettu, zoomataan */
    {
      dragging=0;
      SRGP_setLocatorEchoType(CURSOR);
      zoom_in(&picture, startpos, meas.position);
    }


    if (meas.button_chord[RIGHT_BUTTON] == DOWN) 
    {
      if (dragging == 0)  /* vetäminen aloitetaan, asetetaan kuminauhakursori */
      {
        dragging = 2;
        startpos = meas.position;
	SRGP_setLocatorEchoType(RUBBER_LINE);
	SRGP_setLocatorEchoRubberAnchor(startpos);
      }
    }
    else if(dragging==2)  /* oikea vapautettu, siirretään kuvaa */
    {
      dragging=0;
      SRGP_setLocatorEchoType(CURSOR);
      slide(&picture, startpos, meas.position);
    }
    
    /* Suoritetaan aina, kun hiirtä on liikutettu */
    if((lastpos.x!=meas.position.x) || (lastpos.y!=meas.position.y))
    {
      if(show_coords)  /* Päivitetään koordinaatit */
        print_coords(&picture, meas.position, textbox);

      if(picture.is_mandel && show_prev)  /* Päivitetään Julia preview */
	paint_julia_prev(&picture, meas.position);

      lastpos=meas.position;
    }
  } /* while... */
}





int main() 
{  
  picture.is_mandel = TRUE;   /* Aluksi Mandelbrot */
  picture.area = SRGP_defRectangle(0, 0, INIT_W, INIT_H);  /* Ikkunan alkukoko  */
  init_coords(&picture);       
  SRGP_begin("Mandelbrot & Julia", INIT_W, INIT_H, 4, FALSE); /* 16 väriä */
  SRGP_disableDebugAids();
  init_colors();
  SRGP_setBackgroundColor(SRGP_BLACK);
  repaint(&picture, picture.area);
  SRGP_allowResize(TRUE);  /* Käyttäjä voi muuttaa ikkunan kokoa */
  SRGP_registerResizeCallback(resize_callback);

  process_input();

  SRGP_end();
  return 0;
}














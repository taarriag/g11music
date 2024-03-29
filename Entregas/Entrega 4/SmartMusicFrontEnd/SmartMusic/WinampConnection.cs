﻿using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using WinampFrontEndLib;
using System.Diagnostics;


namespace SmartMusic
{
    public delegate void TrackChangedEventHandler(string song);

    public class WinampConnection
    {
        private int ldr_level;
        private int snd_level;
        private int ldr_count;
        private int snd_count;
        private int ldr_last;
        private int snd_last;
        Process winamp;
        private string currentSong;
        private ColaCircular lightQueue;
        private ColaCircular soundQueue;

        public event TrackChangedEventHandler TrackChanged;

        public WinampConnection()
        {
            this.snd_level = 1;
            this.ldr_level = 1;
            this.ldr_count = 0;
            this.snd_count = 0;
            this.ldr_last = 1;
            this.snd_last = 1;
            winamp = new Process();
            this.lightQueue = new ColaCircular(200);
            this.soundQueue = new ColaCircular(200);
        }

        public string GetCurrentTrack()
        {
            return WinampLib.GetCurrentSongTitle();
        }

        /// <summary>
        /// Recibe un string y determina los niveles de sonido y luz
        /// a partir de este string. 
        /// 
        /// Si estos niveles son distintos a los anteriores, cambia la lista de 
        /// reproduccion en winamp.
        /// </summary>
        /// <param name="text">String en el cual deben estar escritos los niveles (en decimal)</param>
        public void GetNewLevels(string text)
        {
            int max = Int32.Parse(text);
            if (max <= 33 && max>=11)
            {
                char[] levels = text.ToCharArray();
                int new_ldr_level = this.lightQueue.agregar(max/10);
                int new_snd_level = this.soundQueue.agregar(max%10);

                if (new_ldr_level == ldr_level)
                    ldr_count++;

                else
                {
                    ldr_count = 0;
                    ldr_level = new_ldr_level;
                }

                if (new_snd_level == snd_level)
                    snd_count++;

                else
                {
                    snd_count = 0;
                    snd_level = new_snd_level;
                }

                if ((ldr_count == 20 && ldr_level != ldr_last) || (snd_count == 20 && snd_level != snd_last))
                {
                    if (ldr_count == 20 && ldr_level != ldr_last)
                    {
                        ldr_last = ldr_level;
                        ldr_count = 0;
                    }

                    if (snd_count == 20 && snd_level != snd_last)
                    {
                        snd_last = snd_level;
                        snd_count = 0;
                    }

                    ChangePlaylist(ldr_level, snd_level);
                }
            }            
        }

        /// <summary>
        /// Obtiene una accion a partir de un string 
        /// </summary>
        /// <param name="text"></param>
        public void GetAction(string text)
        {
            int max = Int32.Parse(text);
            if (max >= 66 && max <= 88)
            {
                if (max == 66) DoAction(1);
                else if (max == 77) DoAction(2);
                else if (max == 88) DoAction(3);
            }  
        }


        /// <summary>
        /// Cambia la lista a reproducir en funcion del
        /// nivel de luz y sonido entrante
        /// </summary>
        /// <param name="new_ldr_level">Nuevo nivel de luz</param>
        /// <param name="new_snd_level">Nuevo nivel de sonido</param>
        public void ChangePlaylist(int new_ldr_level,int new_snd_level)
        {
            if (new_ldr_level <= 4 && new_snd_level <= 4)
            {
                string pl = "" + new_ldr_level + new_snd_level;
                winamp.StartInfo = new ProcessStartInfo("Winamp", pl + ".m3u");
                winamp.Start();
            }
            
        }


        /// <summary>
        /// Realiza una accion basica sobre winamp en funcion del id ingresado
        /// </summary>
        /// <param name="action_id"></param>
        public void DoAction(int action_id)
        {
            switch (action_id)
            {
                case 1:
                    if (WinampLib.GetPlaybackStatus()==0)
                        WinampLib.Play();
                    else
                        WinampLib.Pause();
                    break;
                case 2:
                    WinampLib.PrevTrack();
                    break;
                case 3:
                    WinampLib.NextTrack();
                    break;
                default:
                    break;
            }
        }

        public void ActualizarTrack(object sender, EventArgs e)
        {
            if (!WinampLib.GetCurrentSongTitle().Equals(currentSong, StringComparison.CurrentCultureIgnoreCase))
            {
                currentSong = WinampLib.GetCurrentSongTitle();
                if (TrackChanged != null)
                    TrackChanged(currentSong);
            }
        }
        
    }
}

using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using WinampFrontEndLib;
using System.Diagnostics;


namespace SmartMusic
{
    public class WinampConnection
    {
        private int ldr_level;
        private int snd_level;
        Process winamp;

        public WinampConnection()
        {
            this.snd_level = 1;
            this.ldr_level = 1;
            winamp = new Process();
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
        /// reproducción en winamp.
        /// </summary>
        /// <param name="text">String en el cual deben estar escritos los niveles (en decimal)</param>
        public void GetNewLevels(string text)
        {
            char[] levels = text.ToCharArray();
            int new_ldr_level = (int)levels[0];
            int new_snd_level = (int)levels[1];
            if(new_ldr_level != ldr_level || new_snd_level != snd_level)
            {
                ChangePlaylist(new_ldr_level,new_snd_level);
                ldr_level = new_ldr_level;
                snd_level = new_snd_level; 
            }
        }

        /// <summary>
        /// Cambia la lista a reproducir en función del
        /// nivel de luz y sonido entrante
        /// </summary>
        /// <param name="new_ldr_level">Nuevo nivel de luz</param>
        /// <param name="new_snd_level">Nuevo nivel de sonido</param>
        public void ChangePlaylist(int new_ldr_level,int new_snd_level)
        {
            string pl = "" + new_ldr_level + new_snd_level;
            winamp.StartInfo = new ProcessStartInfo("Winamp", pl + ".m3u");
            winamp.Start();
        }


        /// <summary>
        /// Realiza una acción básica sobre winamp en función del id ingresado
        /// </summary>
        /// <param name="action_id"></param>
        public void DoAction(int action_id)
        {
            switch (action_id)
            {
                case 1:
                    WinampLib.Play();
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
        
    }
}

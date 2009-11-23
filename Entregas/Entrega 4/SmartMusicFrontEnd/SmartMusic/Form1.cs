using System;
using System.Collections.Generic;
using System.ComponentModel;
using System.Data;
using System.Drawing;
using System.Linq;
using System.Text;
using System.Windows.Forms;
using System.IO.Ports;

namespace SmartMusic
{
    public partial class Form1 : Form
    {
        Timer timer = new Timer();
        private WinampConnection winampConnection;
        private SerialComm serialComm;
        
        public Form1()
        {
            InitializeComponent();
            winampConnection = new WinampConnection();

            for(int i=1;i<4;i++)
            {
                for(int j=1;j<4;j++)
                {
                    listBox1.Items.Add("" + i + j);
                }
            }

            winampConnection.TrackChanged += new TrackChangedEventHandler(winampConnection_TrackChanged);
            

            this.InitializePorts();
        }

        void winampConnection_TrackChanged(string song)
        {
            //serialComm.Send("a");
            //serialComm.Send(song);
        }

        private void InitializePorts()
        {
            string[] ports = SerialPort.GetPortNames();
            for (int i = 0; i < ports.Length; i++)
            {
                this.portComboBox.Items.Add(ports[i]);
            }
            
        }

        private void executeButton_Click(object sender, EventArgs e)
        {
            serialComm = new SerialComm(this.portComboBox.SelectedItem.ToString());
            serialComm.IncomingInfoEvent+=new IncomingInfoEventHandler(winampConnection.GetNewLevels);
            serialComm.IncomingInfoEvent+=new IncomingInfoEventHandler(winampConnection.GetAction);
            serialComm.Start();
            ListenWinamp();
            //serialComm.Send('h');
        }


        private void button4_Click(object sender, EventArgs e)
        {
            char[] levels = listBox1.SelectedItem.ToString().ToCharArray();
            int ldr = Int32.Parse(""+levels[0]);
            int snd = Int32.Parse(""+levels[1]);
            this.winampConnection.ChangePlaylist(ldr, snd);
        }

        private void button1_Click(object sender, EventArgs e)
        {
            winampConnection.DoAction(1);
        }

        public void ListenWinamp()
        {
            timer.Interval = 1 * 1000;
            timer.Tick += new EventHandler(winampConnection.ActualizarTrack);
            timer.Start();
        }

        private void button3_Click(object sender, EventArgs e)
        {
            winampConnection.DoAction(3);
        }








    }
}

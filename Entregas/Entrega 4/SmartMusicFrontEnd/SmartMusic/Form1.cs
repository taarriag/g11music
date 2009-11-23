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
            winampConnection.TrackChanged += new TrackChangedEventHandler(winampConnection_TrackChanged);
            this.InitializePorts();
        }

        void winampConnection_TrackChanged(string song)
        {
            //Se ha comentado esta linea debido a que el PIC genera problemas al recibir info 
            //desde el PC.
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

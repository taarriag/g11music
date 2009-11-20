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

            this.InitializePorts();
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








    }
}

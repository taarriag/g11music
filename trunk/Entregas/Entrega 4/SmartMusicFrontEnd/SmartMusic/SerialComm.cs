using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.IO.Ports;
using System.Windows.Forms;
using System.Threading;

namespace SmartMusic
{
    public delegate void IncomingInfoEventHandler(string info);

    public class SerialComm
    {
        private SerialPort sp;
        public event IncomingInfoEventHandler IncomingInfoEvent;

        /// <summary>
        /// Obtiene el puerto de esta comunicacion serial
        /// </summary>
        public string Port
        {
            set { this.sp.PortName = value; }
            get { return this.sp.PortName; }
        }

        /// <summary>
        /// Inicializa una instancia de comunicacion serial en el puerto de nombre portName
        /// </summary>
        /// <param name="portName">Nombre del puerto en el cual se inicializara la comunicacion</param>
        public SerialComm(string portName)
        {
            sp = new SerialPort();
            sp.BaudRate = 9600;
            sp.DataReceived += new SerialDataReceivedEventHandler(sp_DataReceived);
            sp.PortName = portName;
        }
        
        /// <summary>
        /// Abre el puerto asociado a esta instancia de SerialComm, 
        /// inicializando la conexion con el pic.
        /// </summary>
        public void Start()
        {
            try
            {
                sp.Open();
            }

            catch (Exception e)
            {
                MessageBox.Show("The port " + sp.PortName + " could not be opened.");
            }
        }

        /// <summary>
        /// Cierra el puerto asociado a esta instancia de SerialComm
        /// </summary>
        public void Close()
        {
            if (sp.IsOpen)
                sp.Close();
        
        }

        /// <summary>
        /// Metodo encargado de recibir los datos provenientes desde el PIC, generando un string
        /// y ejecutando el metodo ProcReceived.
        /// </summary>
        /// <param name="sender"></param>
        /// <param name="e"></param>
        private void sp_DataReceived(object sender, SerialDataReceivedEventArgs e)
        {
            byte[] buffer = new byte[sp.ReadBufferSize];
            int count = 0;
            string readed_line = "";

            //readed_line += sp.ReadByte();
            sp.Read(buffer, sp.ReadBufferSize * count, sp.ReadBufferSize);
            readed_line += buffer[0];
            /*
            while (sp.BytesToRead > 0)
            {
                readed_line += sp.Read(buffer, sp.ReadBufferSize * count, sp.ReadBufferSize);
                //readed_line += sp.Read(buffer, sp.ReadBufferSize * count, 1);
            }
             */ 
            ProcReceived(readed_line);
        }

        /// <summary>
        /// Recibe una linea leida a partir de la info del PIC y dispara 
        /// el evento IncomingInfoEvent, entregandole como parametro la linea leida.
        /// </summary>
        /// <param name="readed_line"></param>
        private void ProcReceived(string readed_line)
        {
            if (IncomingInfoEvent != null)
                IncomingInfoEvent(readed_line);
            
        }

        public void Send(byte[] Info)
        {
            sp.Write(Info, 0, Info.Length);
        }

        public void Send(byte Info)
        {
            byte[] info = new byte[1];
            info[0] = Info;
            sp.Write(info, 0, info.Length);
        }

        public void Send(string Info)
        {
            string[] msg = Info.Split(' ');
            byte[] msg_byte = new byte[msg.Length];
            string display = "";
            for (int i = 0; i < msg.Length - 1; i++)
            {
                msg_byte[i] = System.Convert.ToByte(msg[i].ToCharArray()[0]);
                display += msg_byte[i].ToString() + " ";
                Send(msg_byte[i]);
                Thread.Sleep(1000);
                //ProcSent(msg_byte[i].ToString());
            }
        }



    }
}

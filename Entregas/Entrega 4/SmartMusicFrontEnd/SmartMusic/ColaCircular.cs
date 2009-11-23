using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;

namespace SmartMusic
{
    class ColaCircular
    {
        private int puntero;
        private int suma;
        private int[] cola;

        public ColaCircular(int largo)
        {
            puntero = 0;
            suma = largo;
            cola = new int[largo];

            for (int i = 0; i < cola.Length; i++)
                cola[i] = 1;
        }

        public int agregar(int x)
        {
            suma = suma - cola[puntero] + x;
            cola[puntero] = x;
            puntero = (puntero + 1) % cola.Length;
            return suma / cola.Length;
        }
    }
}

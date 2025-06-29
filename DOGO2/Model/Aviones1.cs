using System.ComponentModel.DataAnnotations;

namespace DOGO2.Model
{
    public class Aviones1
    {
        [Key]
        public int IdAvion { get; set; }
        public int IdTipoAvion { get; set; }
        public int IdCategoriaAvion { get; set; }
        public string Matricula { get; set; }
        public string Nombre { get; set; }
        public string Modelo { get; set; }

    }
}

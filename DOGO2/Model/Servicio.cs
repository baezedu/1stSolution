using System.ComponentModel.DataAnnotations;

namespace DOGO2.Model
{
    public class Servicio
    {
        [Key]
        public int IdServicio { get; set; }
        
        [Required]
        [StringLength(100)]
        public string Nombre { get; set; }
        
        [Required]
        [StringLength(500)]
        public string Descripcion { get; set; }
        
        [Required]
        public decimal PrecioHora { get; set; }
        
        [Required]
        [StringLength(50)]
        public string TipoServicio { get; set; }
        
        [StringLength(200)]
        public string ImagenUrl { get; set; }
        
        public bool Disponible { get; set; }
    }
}

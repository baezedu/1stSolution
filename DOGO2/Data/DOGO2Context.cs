using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Microsoft.EntityFrameworkCore;
using DOGO2.Model;

namespace DOGO2.Data
{
    public class DOGO2Context(DbContextOptions<DOGO2Context> options) : DbContext(options)
    {
        public DbSet<Aviones1> Aviones1 { get; set; } = default!;

        protected override void OnModelCreating(ModelBuilder modelBuilder)
        {
            // No agregues HasNoKey aquí, EF detectará la clave primaria por el atributo [Key] en Aviones1
            base.OnModelCreating(modelBuilder);
        }
    }
}

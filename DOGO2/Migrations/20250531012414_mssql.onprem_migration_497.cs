using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace DOGO2.Migrations
{
    /// <inheritdoc />
    public partial class mssqlonprem_migration_497 : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.CreateTable(
                name: "Aviones1",
                columns: table => new
                {
                    IdAvion = table.Column<int>(type: "int", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    IdTipoAvion = table.Column<int>(type: "int", nullable: false),
                    IdCategoriaAvion = table.Column<int>(type: "int", nullable: false),
                    Matricula = table.Column<string>(type: "nvarchar(max)", nullable: false),
                    Nombre = table.Column<string>(type: "nvarchar(max)", nullable: false),
                    Modelo = table.Column<string>(type: "nvarchar(max)", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_Aviones1", x => x.IdAvion);
                });
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "Aviones1");
        }
    }
}

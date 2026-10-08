pragma Ada_2022;
package Diagonal_Traverse with SPARK_Mode => On is
   Side : constant := 4;
   subtype Index is Positive range 1 .. Side;
   subtype Position is Positive range 1 .. Side * Side;
   subtype Pixel is Integer range 0 .. 99;
   type Matrix is array (Index, Index) of Pixel;
   type Sequence is array (Position) of Pixel;
   procedure Traverse (Input : in Matrix; Output : out Sequence);
end Diagonal_Traverse;

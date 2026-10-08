pragma Ada_2022;
package Lucky_Numbers with SPARK_Mode => On is
   Side : constant := 4;
   subtype Index is Positive range 1 .. Side;
   subtype Pixel is Integer range 0 .. 99;
   type Matrix is array (Index, Index) of Pixel;
   procedure Find (Input : in Matrix; Value : out Pixel; Found : out Boolean);
end Lucky_Numbers;

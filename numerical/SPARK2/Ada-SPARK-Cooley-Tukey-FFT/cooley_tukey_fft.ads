--  Bounded Ada/SPARK fixed-point Cooley-Tukey FFT (educational SAR building block).
pragma Ada_2022;
package Cooley_Tukey_FFT
  with SPARK_Mode => On
is
   N     : constant := 8;
   Scale : constant := 1024;

   subtype Sample is Integer range -2048 .. 2048;
   type Complex is record
      Re : Sample := 0;
      Im : Sample := 0;
   end record;

   subtype Index is Natural range 0 .. N - 1;
   type Complex_Array is array (Index) of Complex;

   --  In-place radix-2 DIT FFT, N=8. Twiddles are Q10 fixed-point (no IEEE
   --  floats). Output is unnormalized (no 1/N scale).
   procedure FFT (X : in out Complex_Array)
     with Global => null;

end Cooley_Tukey_FFT;

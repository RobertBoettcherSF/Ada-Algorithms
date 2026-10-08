--  Euclidean algorithm body.

pragma Ada_2022;

package body Euclidean
  with SPARK_Mode => Off
is

   function Abs_LI (N : Long_Integer) return Long_Integer is
   begin
      if N < 0 then
         return -N;
      else
         return N;
      end if;
   end Abs_LI;

   function Gcd (A, B : Long_Integer) return Long_Integer is
      U : Long_Integer := Abs_LI (A);
      V : Long_Integer := Abs_LI (B);
      T : Long_Integer;
   begin
      while V /= 0 loop
         T := U rem V;
         U := V;
         V := T;
      end loop;
      return U;
   end Gcd;

   function Lcm (A, B : Long_Integer) return Long_Integer is
      AA : constant Long_Integer := Abs_LI (A);
      BB : constant Long_Integer := Abs_LI (B);
      G  : Long_Integer;
   begin
      if AA = 0 and then BB = 0 then
         return 0;
      end if;
      if AA > Max_Educational or else BB > Max_Educational then
         raise Invalid_Argument;
      end if;
      G := Gcd (AA, BB);
      --  (AA / G) * BB is exact and fits for educational sizes.
      return (AA / G) * BB;
   end Lcm;

   function Are_Coprime (A, B : Long_Integer) return Boolean is
   begin
      return Gcd (A, B) = 1;
   end Are_Coprime;

   function Division_Steps (A, B : Long_Integer) return Natural is
      U : Long_Integer := Abs_LI (A);
      V : Long_Integer := Abs_LI (B);
      T : Long_Integer;
      Steps : Natural := 0;
   begin
      while V /= 0 loop
         T := U rem V;
         U := V;
         V := T;
         Steps := Steps + 1;
      end loop;
      return Steps;
   end Division_Steps;

   function Binary_Gcd (A, B : Long_Integer) return Long_Integer is
      U : Long_Integer := Abs_LI (A);
      V : Long_Integer := Abs_LI (B);
      Shift : Natural := 0;
   begin
      if U = 0 then
         return V;
      elsif V = 0 then
         return U;
      end if;

      while (U rem 2 = 0) and then (V rem 2 = 0) loop
         U := U / 2;
         V := V / 2;
         Shift := Shift + 1;
      end loop;

      while U rem 2 = 0 loop
         U := U / 2;
      end loop;

      loop
         while V rem 2 = 0 loop
            V := V / 2;
         end loop;
         if U > V then
            declare
               T : constant Long_Integer := U;
            begin
               U := V;
               V := T;
            end;
         end if;
         V := V - U;
         exit when V = 0;
      end loop;

      return U * (2 ** Shift);
   end Binary_Gcd;

end Euclidean;

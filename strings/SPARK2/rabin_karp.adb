pragma Ada_2022;
package body Rabin_Karp
  with SPARK_Mode => On
is
   Base : constant := 256;
   Modulus : constant := 10007;

   function Hash (S : String) return Natural is
      H : Natural := 0;
   begin
      for C of S loop
         pragma Loop_Invariant (H < Modulus);
         H := (H * Base + Character'Pos (C)) rem Modulus;
      end loop;
      return H;
   end Hash;

   function Search (Text, Pat : String) return Boolean is
      PH : constant Natural := Hash (Pat);
      N  : constant Natural := Text'Length;
      M  : constant Natural := Pat'Length;
   begin
      if M > N then
         return False;
      end if;
      for I in Text'First .. Text'First + (N - M) loop
         pragma Loop_Invariant (True);
         declare
            Window : constant String := Text (I .. I + M - 1);
         begin
            if Hash (Window) = PH and then Window = Pat then
               return True;
            end if;
         end;
      end loop;
      return False;
   end Search;
end Rabin_Karp;

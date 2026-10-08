pragma Ada_2022;
package body Randomized_Collection with SPARK_Mode => On is
   function Empty return Collection is
   begin
      return (Data => (others => 0), Count_Stored => 0);
   end Empty;

   function Size (C : Collection) return Count is
   begin
      return C.Count_Stored;
   end Size;

   procedure Add (C : in out Collection; V : Value) is
   begin
      case C.Count_Stored is
         when 0 => C.Data (1) := V;
         when 1 => C.Data (2) := V;
         when 2 => C.Data (3) := V;
         when 3 => C.Data (4) := V;
         when 4 => C.Data (5) := V;
         when 5 => C.Data (6) := V;
         when 6 => C.Data (7) := V;
         when 7 => C.Data (8) := V;
         when 8 => null;
      end case;
      if C.Count_Stored < Capacity then C.Count_Stored := C.Count_Stored + 1; end if;
   end Add;

   function Contains (C : Collection; V : Value) return Boolean is
   begin
      if C.Count_Stored >= 1 and then C.Data (1) = V then return True; end if;
      if C.Count_Stored >= 2 and then C.Data (2) = V then return True; end if;
      if C.Count_Stored >= 3 and then C.Data (3) = V then return True; end if;
      if C.Count_Stored >= 4 and then C.Data (4) = V then return True; end if;
      if C.Count_Stored >= 5 and then C.Data (5) = V then return True; end if;
      if C.Count_Stored >= 6 and then C.Data (6) = V then return True; end if;
      if C.Count_Stored >= 7 and then C.Data (7) = V then return True; end if;
      if C.Count_Stored >= 8 and then C.Data (8) = V then return True; end if;
      return False;
   end Contains;

   procedure Next (S : in out Seed; V : out Value) is
   begin
      if S = Seed'Last then S := Seed'First; else S := S + 1; end if;
      V := Value (S mod 101) - 100;
   end Next;
end Randomized_Collection;

--  Own tests for Interleaving_String (see tests/SOURCES.txt).
--  Is_Interleaving must agree with an own recursive interleaving check.
pragma Ada_2022;
with Ada.Text_IO;
with Interleaving_String; use Interleaving_String;

procedure Own_Checks is
   Failures : Natural := 0;
   Cases    : Natural := 0;

   --  Park-Miller "minimal standard" generator (x := 16807 x mod (2**31 - 1)).

   procedure Report (Ok : Boolean; Label : String) is
   begin
      Cases := Cases + 1;
      if not Ok then
         Failures := Failures + 1;
         if Failures <= 5 then
            Ada.Text_IO.Put_Line ("  FAIL own check: " & Label);
         end if;
      end if;
   end Report;

   type Words is array (0 .. 30) of Word;
   type Lens is array (0 .. 30) of Length;
   Ws : Words;
   Ls : Lens;
   function Ref (A, B, C : Word; NA, NB, NC : Natural; I, J : Natural) return Boolean is
      --  can C (I + J + 1 .. NC) be formed from A (I + 1 .. NA) and B (J + 1 .. NB)?
   begin
      if I = NA and then J = NB then
         return I + J = NC;
      end if;
      if I + J >= NC then
         return False;
      end if;
      return (I < NA and then A (I + 1) = C (I + J + 1) and then Ref (A, B, C, NA, NB, NC, I + 1, J))
        or else (J < NB and then B (J + 1) = C (I + J + 1) and then Ref (A, B, C, NA, NB, NC, I, J + 1));
   end Ref;
begin
   --  all 31 words of length 0 .. 4 over {0, 1}; unused positions hold a third symbol
   declare
      K : Natural := 0;
   begin
      for L in 0 .. 4 loop
         for Code in 0 .. 2 ** L - 1 loop
            Ws (K) := [others => 7];
            for P in 1 .. L loop
               Ws (K) (P) := (Code / 2 ** (P - 1)) mod 2;
            end loop;
            Ls (K) := L;
            K := K + 1;
         end loop;
      end loop;
   end;
   for IA in Ws'Range loop
      for IB in Ws'Range loop
         for IC in Ws'Range loop
            Report (Is_Interleaving (Ws (IA), Ws (IB), Ws (IC), Ls (IA), Ls (IB), Ls (IC))
                    = Ref (Ws (IA), Ws (IB), Ws (IC), Ls (IA), Ls (IB), Ls (IC), 0, 0), "triple");
         end loop;
      end loop;
   end loop;
   if Failures > 0 then
      Ada.Text_IO.Put_Line ("FAIL own checks:" & Failures'Image & " of" & Cases'Image);
      raise Program_Error with "own checks failed";
   end if;
   Ada.Text_IO.Put_Line ("PASS own checks:" & Cases'Image & " inputs (own recursive interleaving reference, exhaustive)");
end Own_Checks;

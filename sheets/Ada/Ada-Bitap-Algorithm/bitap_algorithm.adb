--  Bitap_Algorithm body — shift-and exact + Wu–Manber approximate Bitap.

pragma Ada_2022;

with Interfaces; use Interfaces;

package body Bitap_Algorithm
  with SPARK_Mode => Off
is

   subtype Alphabet_Index is Natural range 0 .. 255;
   type Mask_Array is array (Alphabet_Index) of Unsigned_64;

   --  R[0 .. K] state vectors for approximate search (K ≤ Max_Pattern_Len).
   type State_Array is array (Natural range <>) of Unsigned_64;

   procedure Check_Common (Text, Pattern : String) is
   begin
      if Pattern'Length = 0 then
         raise Invalid_Argument with "empty pattern";
      end if;
      if Pattern'Length > Max_Pattern_Len then
         raise Invalid_Argument with "pattern longer than Max_Pattern_Len";
      end if;
      if Text'Length > Max_Text_Len then
         raise Invalid_Argument with "text longer than Max_Text_Len";
      end if;
   end Check_Common;

   --  Pattern_Mask[c] has bit i set iff Pattern (Pattern'First + i) = c.
   function Build_Masks (Pattern : String) return Mask_Array is
      M : Mask_Array := [others => 0];
      Bit : Unsigned_64 := 1;
   begin
      for I in Pattern'Range loop
         M (Character'Pos (Pattern (I))) :=
           M (Character'Pos (Pattern (I))) or Bit;
         Bit := Shift_Left (Bit, 1);
      end loop;
      return M;
   end Build_Masks;

   --  Educational Levenshtein distance (Wagner–Fischer), used only to
   --  recover the leftmost start index once Bitap reports a match end.
   function Levenshtein (A, B : String) return Natural is
      La : constant Natural := A'Length;
      Lb : constant Natural := B'Length;
   begin
      if La = 0 then
         return Lb;
      end if;
      if Lb = 0 then
         return La;
      end if;
      if A = B then
         return 0;
      end if;

      declare
         Prev : array (0 .. Lb) of Natural;
         Curr : array (0 .. Lb) of Natural;
         Cost : Natural;
      begin
         for J in 0 .. Lb loop
            Prev (J) := J;
         end loop;

         for I in 1 .. La loop
            Curr (0) := I;
            for J in 1 .. Lb loop
               if A (A'First + I - 1) = B (B'First + J - 1) then
                  Cost := 0;
               else
                  Cost := 1;
               end if;
               Curr (J) :=
                 Natural'Min
                   (Curr (J - 1) + 1,
                    Natural'Min (Prev (J) + 1, Prev (J - 1) + Cost));
            end loop;
            for Jj in 0 .. Lb loop
               Prev (Jj) := Curr (Jj);
            end loop;
         end loop;

         return Prev (Lb);
      end;
   end Levenshtein;

   --  Among starts in Lo .. End_Index that form a substring of Text with
   --  Levenshtein distance ≤ K to Pattern, return the smallest start, or
   --  Not_Found if none (should not happen when Bitap fired correctly).
   function Recover_Start
     (Text, Pattern : String;
      End_Index     : Positive;
      K             : Natural) return Integer
   is
      M      : constant Positive := Pattern'Length;
      Lo_Off : Integer;
      Lo     : Positive;
   begin
      Lo_Off := Integer (End_Index) - Integer (M) - Integer (K) + 1;
      if Lo_Off < Integer (Text'First) then
         Lo := Text'First;
      else
         Lo := Positive (Lo_Off);
      end if;

      for S in Lo .. End_Index loop
         if Levenshtein (Text (S .. End_Index), Pattern) <= K then
            return Integer (S);
         end if;
      end loop;

      return Not_Found;
   end Recover_Start;

   ---------------------------------------------------------------------------
   -- Exact Bitap (shift-and)
   ---------------------------------------------------------------------------

   function Find_Exact (Text, Pattern : String) return Integer is
      M     : Positive;
      Masks : Mask_Array;
      R     : Unsigned_64 := 0;
      Match : Unsigned_64;
      Bit   : Unsigned_64;
   begin
      Check_Common (Text, Pattern);
      M := Pattern'Length;
      Masks := Build_Masks (Pattern);
      Match := Shift_Left (1, M - 1);

      for J in Text'Range loop
         Bit := Masks (Character'Pos (Text (J)));
         R := (Shift_Left (R, 1) or 1) and Bit;
         if (R and Match) /= 0 then
            return Integer (J) - M + 1;
         end if;
      end loop;

      return Not_Found;
   end Find_Exact;

   function Contains_Exact (Text, Pattern : String) return Boolean is
   begin
      return Find_Exact (Text, Pattern) /= Not_Found;
   end Contains_Exact;

   ---------------------------------------------------------------------------
   -- Approximate Bitap (Wu–Manber, full Levenshtein)
   ---------------------------------------------------------------------------

   function Find_Approx
     (Text, Pattern : String;
      K             : Natural) return Integer
   is
      M     : Positive;
      Masks : Mask_Array;
      Match : Unsigned_64;
      Best  : Integer := Not_Found;
   begin
      Check_Common (Text, Pattern);

      if K > Max_Pattern_Len then
         raise Invalid_Argument with "K exceeds Max_Pattern_Len";
      end if;

      if K = 0 then
         return Find_Exact (Text, Pattern);
      end if;

      if Text'Length = 0 then
         return Not_Found;
      end if;

      M := Pattern'Length;
      Masks := Build_Masks (Pattern);
      Match := Shift_Left (1, M - 1);

      declare
         R    : State_Array (0 .. K) := [others => 0];
         Old  : Unsigned_64;
         Tmp  : Unsigned_64;
         Bit  : Unsigned_64;
         Cand : Integer;
         --  Earliest possible start for a match ending at current J:
         --  J − M − K + 1. Once that exceeds Best we can stop.
         Early_Stop_Slack : constant Integer :=
           Integer (M) + Integer (K) - 1;
      begin
         --  Boundary: allow d leading deletions before any text.
         for D in 1 .. K loop
            R (D) := Shift_Left (1, D) - 1;
         end loop;

         --  If K ≥ M the whole pattern can be deleted with no text;
         --  report Text'First as an empty-prefix match only when we
         --  still have text (empty Text already returned Not_Found).
         --  Skip pre-loop report so every hit is tied to a text index.

         for J in Text'Range loop
            Bit := Masks (Character'Pos (Text (J)));
            Old := R (0);
            R (0) := (Shift_Left (Old, 1) or 1) and Bit;

            for D in 1 .. K loop
               Tmp := R (D);
               --  match | substitution | insertion | deletion
               R (D) :=
                 ((Shift_Left (Tmp, 1) or 1) and Bit)
                 or (Shift_Left (Old, 1) or 1)
                 or Old
                 or (Shift_Left (R (D - 1), 1) or 1);
               Old := Tmp;
            end loop;

            if (R (K) and Match) /= 0 then
               Cand := Recover_Start (Text, Pattern, J, K);
               if Cand /= Not_Found then
                  if Best = Not_Found or else Cand < Best then
                     Best := Cand;
                  end if;
               end if;
            end if;

            --  No later end can produce a start strictly before Best.
            if Best /= Not_Found
              and then Integer (J) - Early_Stop_Slack + 1 > Best
            then
               exit;
            end if;
         end loop;

         return Best;
      end;
   end Find_Approx;

end Bitap_Algorithm;

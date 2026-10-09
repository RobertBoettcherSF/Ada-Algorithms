pragma Ada_2022;
package body Super_Ugly_Number_Stub with SPARK_Mode => On is

   --  Classic multi-pointer merge: U (1) = 1; U (K) is the smallest
   --  U (Idx (J)) * F (J); every J reaching that value moves on (so equal
   --  products, from repeated or composite factors, appear once).
   procedure Nth_Super_Ugly_General
     (Factors : Factor_List; N : N_Range; Value : out Ugly_Value; Fits : out Boolean)
   is
      type Value_Table is array (N_Range) of Ugly_Value;
      type Index_Table is array (Factor_Index) of N_Range;
      U    : Value_Table := [others => 1];
      Idx  : Index_Table := [others => 1];
      Next : Long_Long_Integer;
      Cand : Long_Long_Integer;
   begin
      pragma Assert (for all I in 0 .. 30 => Pow2 (I + 1) = 2 * Pow2 (I));
      for K in 2 .. N loop
         pragma Loop_Invariant (for all J in Factors'Range => Idx (J) <= K - 1);
         pragma Loop_Invariant
           (if Has_Two (Factors) and then K <= 32 then
              (for all I in 1 .. K - 1 => Long_Long_Integer (U (I)) <= Pow2 (K - 2)));
         Next := Long_Long_Integer (U (Idx (Factors'First))) * Long_Long_Integer (Factors (Factors'First));
         for J in Factors'Range loop
            Cand := Long_Long_Integer (U (Idx (J))) * Long_Long_Integer (Factors (J));
            if Cand < Next then
               Next := Cand;
            end if;
            pragma Loop_Invariant (Next in 2 .. Long_Long_Integer (Integer'Last) * 1_000);
            pragma Loop_Invariant
              (for all L in Factors'First .. J =>
                 Next <= Long_Long_Integer (U (Idx (L))) * Long_Long_Integer (Factors (L)));
         end loop;
         if Next > Long_Long_Integer (Integer'Last) then
            Value := 1;
            Fits  := False;
            return;
         end if;
         U (K) := Ugly_Value (Next);
         for J in Factors'Range loop
            if Long_Long_Integer (U (Idx (J))) * Long_Long_Integer (Factors (J)) = Next then
               Idx (J) := Idx (J) + 1;
            end if;
            pragma Loop_Invariant (for all L in Factors'Range => Idx (L) <= K);
         end loop;
      end loop;
      Value := U (N);
      Fits  := True;
   end Nth_Super_Ugly_General;

   function Nth_Super_Ugly (N : N_Index) return Small_Ugly is
      V  : Ugly_Value;
      Ok : Boolean;
      F  : constant Factor_List := [2, 7, 13, 19];
   begin
      pragma Assert (Has_Two (F));
      Nth_Super_Ugly_General (F, N, V, Ok);
      pragma Assert (Ok);
      return V;
   end Nth_Super_Ugly;
end Super_Ugly_Number_Stub;

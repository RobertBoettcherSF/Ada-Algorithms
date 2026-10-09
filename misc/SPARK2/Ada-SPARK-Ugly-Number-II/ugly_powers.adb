pragma Ada_2022;

package body Ugly_Powers with SPARK_Mode => On is

   --  B ** E.
   function Pow (B : Positive; E : Natural) return Big_Integer
   with Global => null, Post => Pow'Result >= 1, Subprogram_Variant => (Decreases => E);

   function Pow (B : Positive; E : Natural) return Big_Integer is
     (if E = 0 then To_Big_Integer (1) else To_Big_Integer (B) * Pow (B, E - 1));

   function Val3 (A, B, C : Natural) return Big_Integer is
     (Pow (2, A) * Pow (3, B) * Pow (5, C));

   procedure Lemma_Two (A, B, C : Natural) is
   begin
      pragma Assert (Pow (2, A + 1) = 2 * Pow (2, A));
   end Lemma_Two;

   procedure Lemma_Three (A, B, C : Natural) is
   begin
      pragma Assert (Pow (3, B + 1) = 3 * Pow (3, B));
   end Lemma_Three;

   procedure Lemma_Five (A, B, C : Natural) is
   begin
      pragma Assert (Pow (5, C + 1) = 5 * Pow (5, C));
   end Lemma_Five;
end Ugly_Powers;

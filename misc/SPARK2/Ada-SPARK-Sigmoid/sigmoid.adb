pragma Ada_2022;
package body Sigmoid with SPARK_Mode => On is

   function Right_Half (X : Big_Integer) return Probability is
      --  S = Num / Den; after the step for N, S = 1 + x/N (1 + .. ).
      Num : Big_Integer := To_Big_Integer (1);
      Den : Big_Integer := To_Big_Integer (1);
      Step : Big_Integer;
      Q   : Big_Integer;
   begin
      for N in reverse 1 .. Terms loop
         Step := To_Big_Integer (1000 * N);
         Num := Den * Step + X * Num;
         Den := Den * Step;
         pragma Loop_Invariant (Den > 0 and then Num >= Den and then (if X = 0 then Num = Den));
      end loop;
      --  floor (100 Num / (Num + Den) + 1/2).
      Q := (201 * Num + Den) / (2 * (Num + Den));
      pragma Assert (201 * Num + Den < 101 * (2 * (Num + Den)));
      pragma Assert (201 * Num + Den >= 50 * (2 * (Num + Den)));
      pragma Assert (Q >= 50 and then Q <= 100);
      pragma Assert (if X = 0 then 201 * Num + Den = 50 * (2 * (Num + Den)) + 2 * Den
                       and then 2 * Den < 2 * (Num + Den));
      pragma Assert (if X = 0 then Q = 50);
      return To_Integer (Q);
   end Right_Half;

   procedure Lemma_Symmetry (X_Milli : Integer) is
   begin
      pragma Assert (-To_Big_Integer (-X_Milli) = To_Big_Integer (X_Milli));
      pragma Assert (-To_Big_Integer (X_Milli) = To_Big_Integer (-X_Milli));
      if X_Milli > 0 then
         pragma Assert (Percent (-X_Milli) = 100 - Right_Half (To_Big_Integer (X_Milli)));
      elsif X_Milli < 0 then
         pragma Assert (Percent (X_Milli) = 100 - Right_Half (To_Big_Integer (-X_Milli)));
      end if;
   end Lemma_Symmetry;

end Sigmoid;

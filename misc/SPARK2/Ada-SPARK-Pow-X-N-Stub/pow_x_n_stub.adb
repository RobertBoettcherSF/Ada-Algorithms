pragma Ada_2022;

package body Pow_X_N_Stub with SPARK_Mode => On is
   procedure Power (X : Integer; N : Natural; Result : out Integer;
                    Ok : out Boolean)
   is
      subtype Big is Long_Long_Integer;
      Lo  : constant Big := Big (Integer'First);
      Hi  : constant Big := Big (Integer'Last);
      Acc : Big := 1;
      B   : Big := Big (X);
      E   : Natural := N;
   begin
      Result := 0;
      Ok := False;
      while E > 0 loop
         pragma Loop_Invariant (Acc in Lo .. Hi and then B in Lo .. Hi);
         pragma Loop_Invariant (if X = 1 then Acc = 1 and then B = 1);
         pragma Loop_Invariant
           (if N = 1 then E = 1 and then Acc = 1 and then B = Big (X));
         if E mod 2 = 1 then
            Acc := Acc * B;
            if Acc not in Lo .. Hi then
               return;
            end if;
         end if;
         E := E / 2;
         if E > 0 then
            --  B * B overflows Integer only if abs B > 46_340; then any
            --  further factor makes the true result overflow too, unless
            --  Acc is 0 (impossible: B /= 0 and Acc started at 1).
            B := B * B;
            if B not in Lo .. Hi then
               return;
            end if;
         end if;
      end loop;
      Result := Integer (Acc);
      Ok := True;
   end Power;
end Pow_X_N_Stub;

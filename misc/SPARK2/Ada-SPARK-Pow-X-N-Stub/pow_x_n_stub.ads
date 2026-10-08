pragma Ada_2022;

--  Integer power X ** N by repeated squaring (LeetCode 50 over Integer),
--  generalised from the old stub (X in 0 .. 4, N in 0 .. 5, table of
--  cases) to every Integer X and Natural N. Ok is False exactly when the
--  true result does not fit in Integer; Result is then 0.
package Pow_X_N_Stub with SPARK_Mode => On is
   procedure Power (X : Integer; N : Natural; Result : out Integer;
                    Ok : out Boolean)
     with Global => null,
          Post   => (if N = 0 then Ok and then Result = 1)
                    and then (if N = 1 then Ok and then Result = X)
                    and then (if X = 1 then Ok and then Result = 1)
                    and then (if not Ok then Result = 0);

end Pow_X_N_Stub;

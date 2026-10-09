--  Pre rejection: numerical/SPARK4/Ada-SPARK-Modular-Arithmetic (package
--  Modular_Arithmetic). A, B uniform over Natural_64, N uniform over
--  Modulus_Type (the parameter types; no tighter documented limit).
with Pre_Rng; use Pre_Rng;
with Modular_Arithmetic; use Modular_Arithmetic;
procedure Pr_Modular is
   F_Name : constant String := "numerical/SPARK4/Ada-SPARK-Modular-Arithmetic";
   Gen    : constant String := "A, B uniform over Natural_64, N uniform over Modulus_Type";
   R2, R1, Ru : Natural := 0;
   function Pre_Two (A, B : Natural_64; N : Modulus_Type) return Boolean is (A < N and then B < N);
   function Pre_One (A : Natural_64; N : Modulus_Type) return Boolean is (A < N);
   function Pre_Inv (A : Natural_64; N : Modulus_Type) return Boolean is (Is_Unit (A, N));
begin
   for K in 1 .. Sample loop
      declare
         A : constant Natural_64 := Draw (0, Max_Modulus);
         B : constant Natural_64 := Draw (0, Max_Modulus);
         N : constant Modulus_Type := Draw (2, Max_Modulus);
      begin
         if not Pre_Two (A, B, N) then R2 := R2 + 1; end if;
         if not Pre_One (A, N) then R1 := R1 + 1; end if;
         if not Pre_Inv (A, N) then Ru := Ru + 1; end if;
      end;
   end loop;
   Report (F_Name, "Add_Mod / Sub_Mod / Mul_Mod", Gen, R2);
   Report (F_Name, "Neg_Mod / Pow_Mod / Multiplicative_Order", Gen, R1);
   Report (F_Name, "Inverse", Gen, Ru);
end Pr_Modular;

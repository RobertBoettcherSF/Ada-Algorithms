with Pn_Counter; use Pn_Counter;

procedure Tests is
   A, B, M : Counter;
begin
   A := Empty;
   B := Empty;
   pragma Assert (Value (A) = 0);

   Increment (A, 1);
   Increment (A, 1);
   Decrement (A, 2);
   pragma Assert (Value (A) = 1);
   pragma Assert (P_At (A, 1) = 2);
   pragma Assert (N_At (A, 2) = 1);

   Increment (B, 1);
   Decrement (B, 2);
   Decrement (B, 2);
   pragma Assert (Value (B) = -1);

   M := A;
   Merge (M, B);
   -- componentwise max: P1=max(2,1)=2, N2=max(1,2)=2 => value 2-2=0
   pragma Assert (P_At (M, 1) = 2);
   pragma Assert (N_At (M, 2) = 2);
   pragma Assert (Value (M) = 0);

   -- idempotent merge
   Merge (M, B);
   pragma Assert (P_At (M, 1) = 2);
   pragma Assert (N_At (M, 2) = 2);
end Tests;

with Softmax; use Softmax;
procedure Tests is
   A : constant Logits := (0, 1, 0);
begin
   pragma Assert (Weight (A, 1) = 21);
   pragma Assert (Weight (A, 2) = 57);
   pragma Assert (Weight (A, 3) = 21);
end Tests;

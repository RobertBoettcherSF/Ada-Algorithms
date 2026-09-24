with Cosine_Similarity; use Cosine_Similarity;
procedure Tests is
   A : constant Vector := (1, 1, 1);
   B : constant Vector := (1, 1, -1);
begin
   pragma Assert (Similarity (A, A) = 100);
   pragma Assert (Similarity (A, B) = 33);
end Tests;

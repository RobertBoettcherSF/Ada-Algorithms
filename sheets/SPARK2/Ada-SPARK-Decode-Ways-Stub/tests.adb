with Decode_Ways_Stub;
procedure Tests is
   A : constant Decode_Ways_Stub.Digit_Seq := (1, 2, 2, 1, 2, 6);
   B : constant Decode_Ways_Stub.Digit_Seq := (1, 0, 1, 2, 0, 6);
begin
   pragma Assert (Decode_Ways_Stub.Count (A) = 13);
   pragma Assert (Decode_Ways_Stub.Count (B) = 1);
end Tests;

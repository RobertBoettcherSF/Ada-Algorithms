with Word_Break_Stub;
procedure Tests is
   A : constant Word_Break_Stub.Letters := (False, True, False, True, False, True);
   B : constant Word_Break_Stub.Letters := (False, True, False, True, True, False);
   C : constant Word_Break_Stub.Letters := (False, False, False, False, False, False);
begin
   pragma Assert (Word_Break_Stub.Can_Break (A));
   pragma Assert (Word_Break_Stub.Can_Break (B));
   pragma Assert (not Word_Break_Stub.Can_Break (C));
end Tests;

with Ada.Text_IO; use Ada.Text_IO;
with Proof_Of_Work; use Proof_Of_Work;

procedure Main is
   Nonce : Nonce_Type;
   Hash  : String (1 .. 64);
begin
   Put_Line ("--- Ada Proof-of-Work System Demonstration ---");
   
   Put_Line ("Executing Hashcash (Difficulty: 2 leading zeros)...");
   Generate_Hashcash (Data => "Ada_Transaction_123", Difficulty => 2, Nonce => Nonce, Hash_Result => Hash);
   
   Put_Line ("Solved!");
   Put_Line ("Nonce Found: " & Nonce'Image);
   Put_Line ("Result Hash: " & Hash);
   
   if Verify_Hashcash ("Ada_Transaction_123", 2, Nonce) then
      Put_Line ("Network Verification: VALID");
   else
      Put_Line ("Network Verification: INVALID");
   end if;
end Main;

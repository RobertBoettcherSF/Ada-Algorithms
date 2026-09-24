--  Asymmetric Key Cryptography (Textbook RSA Implementation)
package Asymmetric_Key is

   type Prime_Value is range 2 .. 65535;
   type Key_Component is range 1 .. 2147483647;
   type Message_Type is range 0 .. 2147483647;

   type Public_Key is record
      N : Key_Component;
      E : Key_Component;
   end record;

   type Private_Key is record
      N : Key_Component;
      D : Key_Component;
   end record;

   Invalid_Prime_Error : exception;
   Invalid_Key_Error   : exception;
   Decryption_Error    : exception;

   function Is_Prime (Value : Prime_Value) return Boolean;

   procedure Generate_Keys
     (P     : in     Prime_Value;
      Q     : in     Prime_Value;
      Pub   :    out Public_Key;
      Priv  :    out Private_Key)
     with Pre  => P /= Q and then Is_Prime (P) and then Is_Prime (Q),
          Post => Pub.N = Key_Component (P) * Key_Component (Q) and then
                  Priv.N = Pub.N;

   function Encrypt
     (M   : Message_Type;
      Pub : Public_Key) return Message_Type
     with Pre  => M < Message_Type (Pub.N),
          Post => Encrypt'Result < Message_Type (Pub.N);

   function Decrypt
     (C    : Message_Type;
      Priv : Private_Key) return Message_Type
     with Pre  => C < Message_Type (Priv.N),
          Post => Decrypt'Result < Message_Type (Priv.N);

   function Sign
     (M    : Message_Type;
      Priv : Private_Key) return Message_Type
     with Pre  => M < Message_Type (Priv.N),
          Post => Sign'Result < Message_Type (Priv.N);

   function Verify
     (M   : Message_Type;
      S   : Message_Type;
      Pub : Public_Key) return Boolean
     with Pre  => M < Message_Type (Pub.N) and then S < Message_Type (Pub.N);

end Asymmetric_Key;

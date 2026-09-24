pragma Ada_2022;
with Interfaces;
package Gray_Code with SPARK_Mode => On is
   subtype Word is Interfaces.Unsigned_32;

   function Encode (Value : Word) return Word with Global => null;
   function Decode (Value : Word) return Word with Global => null;
end Gray_Code;

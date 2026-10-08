pragma Ada_2022;

package First_Bad_Version with SPARK_Mode => On is
   Length : constant := 8;
   subtype Version is Positive range 1 .. Length;
   type Status is (Good, Bad);
   type Version_Array is array (Version) of Status;

   function First_Bad (Versions : Version_Array) return Version
     with Global => null;
end First_Bad_Version;

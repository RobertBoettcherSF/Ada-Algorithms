-- Clean-room educational research allocation buckets.
-- Sum of bucket spends must be <= research budget (from steady income).

with Economy;

package Research_Alloc is

   type Bucket is
     (Weapons, Armor, Shields, Life_Support, Sensors);

   type Allocation is array (Bucket) of Economy.Credits;

   function Total (A : Allocation) return Economy.Credits;

   function Is_Valid (A : Allocation; Budget : Economy.Credits) return Boolean;

   function Empty return Allocation;

   -- Even split of Budget across all buckets (remainder on Weapons).
   function Even_Split (Budget : Economy.Credits) return Allocation;

   procedure Set_Bucket
     (A      : in out Allocation;
      B      : Bucket;
      Amount : Economy.Credits;
      Budget : Economy.Credits;
      Ok     : out Boolean);

end Research_Alloc;

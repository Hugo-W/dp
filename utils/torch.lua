--useful for validating if an object is an instance of a class, 
--even when the class is a super class.
--e.g pattern = "^torch[.]%a*Tensor$"
--typepattern(torch.Tensor(4), pattern) and
--typepattern(torch.DoubleTensor(5), pattern) are both true.
--typepattern(3, pattern)
function torch.typepattern(obj, pattern)
   local class = type(obj)
   if class == 'userdata' then
      class = torch.typename(obj)
   end
   local match = string.match(class, pattern)
   if match == nil then
      match = false
   end
   return match
end
-- DEPRECATED:
typepattern = torch.typepattern
-- END

function torch.typeString_to_tensorType(type_string)
   if type_string == 'cuda' then
      return 'torch.CudaTensor'
   elseif type_string == 'float' then
      return 'torch.FloatTensor'
   elseif type_string == 'double' then
      return 'torch.DoubleTensor'
   end
end

-- warning : doesn't allow non-standard constructors.
-- need to call constructors explicitly, e.g. :
function torch.classof(obj)
   local obj_t = torch.typename(obj)
   if not obj_t then
      error("type"..torch.type(obj).."has no torch.class registered constructor", 2)
   end
   local modula = string.tomodule(obj_t)
   return modula
end

-- returns an empty clone of an obj
function torch.emptyClone(obj)
   error("Deprecated use torch.protoClone instead", 2)
end

-- construct an object using a prototype and initialize it with ...
-- works with any class registered with torch.class
function torch.protoClone(proto, ...)
   local class = torch.classof(proto)
   return class(...)
end

function torch.swapaxes(tensor, new_axes)

   -- new_axes : A table that give new axes of tensor, 
   -- example: to swap axes 2 and 3 in 3D tensor of original axes = {1,2,3}, 
   -- then new_axes={1,3,2}
 
   local sorted_axes = table.copy(new_axes)
   table.sort(sorted_axes)
   
   for k, v in ipairs(sorted_axes) do
      assert(k == v, 'Error: new_axes does not contain all the new axis values')
   end       

   -- tracker is used to track if a dim in new_axes has been swapped
   local tracker = torch.zeros(#new_axes)   
   local new_tensor = tensor

   -- set off a chain swapping of a group of intraconnected dimensions
   _chain_swap = function(idx)
      -- if the new_axes[idx] has not been swapped yet
      if tracker[new_axes[idx]] ~= 1 then
         tracker[idx] = 1
         new_tensor = new_tensor:transpose(idx, new_axes[idx])
         return _chain_swap(new_axes[idx])
      else
         return new_tensor
      end    
   end
   
   for idx = 1, #new_axes do
      if idx ~= new_axes[idx] and tracker[idx] ~= 1 then
         new_tensor = _chain_swap(idx)
      end
   end
   
   return new_tensor
end

function torch.Tensor:dimshuffle(new_axes)
   return torch.swapaxes(self, new_axes)
end

class Object
  def is_integer?
    !!(check = Integer(self) rescue false) && check.try(:to_s) == self.try(:to_s)
  end
end
class Group < ActiveRecord::Base
  has_attached_file :group_image, :styles => { :medium => "300x300>", :thumb => "100x100>" }, :path => "#{Settings.group_images_path}/:id/:style/:filename"
  
  validates_presence_of :name
  validates_uniqueness_of :name
  validates_presence_of :user_id
  
  belongs_to :user
  has_many :group_invites
  belongs_to :pvs_category
  
  has_many :group_members
  has_many :users, :through => :group_members, :order => "users.login ASC"
  
  has_many :group_bill_positions
  has_many :bills, :through => :group_bill_positions
  
  has_many :comments, :as => :commentable
  
  def to_param
    "#{id}_#{name.gsub(/[^A-Za-z]+/i, '_').gsub(/\s/, '_')}"
  end
  
  def display_object_name
    'Group'
  end
  
  def active_members
    users.where("group_members.status != 'BOOTED'")
  end
  
  def is_owner?(u)
    self.user == u
  end
  
  def is_member?(u)
    membership = group_members.where(["group_members.user_id=?", u.id]).first
    return (membership && membership.status != 'BOOTED')
  end
  
  def can_join?(u)
    membership = group_members.where(["group_members.user_id=?", u.id]).first
    
    case join_type
    when 'ANYONE', 'REQUEST'
      return (membership.nil? or membership.status != 'BOOTED') ? true  : false
    when 'INVITE_ONLY'
      if membership and membership.status == 'BOOTED'
        return false
      else
        return !group_invites.where(["user_id=?", u.id]).empty?
      end
    end
  end
  
  def can_moderate?(u)
    return false if u == :false
    return true if self.user == u

    membership = group_members.where(["group_members.user_id=?", u.id]).first
    
    return false if membership.nil?
    return true if membership.status == 'MODERATOR'
    
    return false
  end
  
  def can_post?(u)
    return false if u == :false
    return true if self.user == u

    membership = group_members.where(["group_members.user_id=?", u.id]).first
    
    return false if membership.nil?
    
    case post_type
    when 'ANYONE'
      return true
    when 'MODERATOR'  
      return true if membership.status == 'MODERATOR'
    end
    
    return false
  end
  
  def bills_supported
    bills.where("group_bill_positions.position='support'")
  end
  
  def bills_opposed
    bills.where("group_bill_positions.position='oppose'")
  end  
end

require 'test/unit'
require File.join(File.dirname(__FILE__), 'company')

class ActiveScaffoldDependentProtectTest < Test::Unit::TestCase
  def test_destroy_protected_with_companies
    protected_firm = Company.new(:with_companies)
    assert !protected_firm.send(:authorized_for_delete?)
  end
  
  def test_destroy_protected_with_company
    protected_firm = Company.new(:with_company)
    assert !protected_firm.send(:authorized_for_delete?)
  end
  
  def test_destroy_protected_with_main_company
    protected_firm = Company.new(:with_main_company)
    assert !protected_firm.send(:authorized_for_delete?)
  end
  
  def test_destroy_protected_without_companies
    protected_firm_without_companies = Company.new(:without_companies)
    assert protected_firm_without_companies.send(:authorized_for_delete?)
  end
  
  def test_destroy_protected_without_company
    protected_firm_without_company = Company.new(:without_company)
    assert protected_firm_without_company.send(:authorized_for_delete?)
  end
  
  def test_destroy_protected_without_main_company
    protected_firm_without_main_company = Company.new(:without_main_company)
    assert protected_firm_without_main_company.send(:authorized_for_delete?)
  end
end

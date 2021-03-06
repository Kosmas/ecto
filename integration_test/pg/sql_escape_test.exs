defmodule Ecto.Integration.SQLEscapeTest do
  use Ecto.Integration.Postgres.Case

  test "Repo.all escape" do
    TestRepo.insert(Post.new(text: "hello"))

    query = from(p in Post, select: "'\\")
    assert ["'\\"] == TestRepo.all(query)
  end

  test "Repo.create escape" do
    TestRepo.insert(Post.new(text: "'"))

    query = from(p in Post, select: p.text)
    assert ["'"] == TestRepo.all(query)
  end

  test "Repo.update escape" do
    p = TestRepo.insert(Post.new(text: "hello"))
    TestRepo.update(p.text("'"))

    query = from(p in Post, select: p.text)
    assert ["'"] == TestRepo.all(query)
  end

  test "Repo.update_all escape" do
    TestRepo.insert(Post.new(text: "hello"))
    TestRepo.update_all(Post, text: "'")

    query = from(p in Post, select: p.text)
    assert ["'"] == TestRepo.all(query)

    TestRepo.update_all(from(Post, where: "'" != ""), text: "''")
    assert ["''"] == TestRepo.all(query)
  end

  test "Repo.delete_all escape" do
    TestRepo.insert(Post.new(text: "hello"))
    assert [_] = TestRepo.all(Post)

    TestRepo.delete_all(from(Post, where: "'" == "'"))
    assert [] == TestRepo.all(Post)
  end
end
